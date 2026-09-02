# frozen_string_literal: true

require "rails_helper"

RSpec.describe TalentProfile::Api do
  let!(:workspace) { Organization.create!(name: "Talent Profile", slug: "talent-profile") }
  let!(:other_workspace) { Organization.create!(name: "Other", slug: "talent-profile-other") }
  let!(:user) do
    User.create!(
      name: "Serhii User",
      email: "serhii@example.com",
      password: "Password12345!"
    )
  end
  let!(:membership) { Membership.create!(organization: workspace, user:, role: "workspace_admin") }

  it "keeps Candidate distinct from User while allowing an optional same-workspace link" do
    result = WorkspaceContext.with(workspace, membership:) do
      described_class.create_candidate(
        first_name: "Serhii",
        last_name: "Candidate",
        linked_user_id: user.typed_id,
        profile: { skills: [ "Ruby", "Rails" ] }
      )
    end

    expect(result.dig(:candidate, :id)).to start_with("candidate_")
    expect(result.dig(:candidate, :linked_user_id)).to eq(user.typed_id)
    expect(result.dig(:candidate, :id)).not_to eq(user.typed_id)
    expect(result.dig(:profile_version, :version_number)).to eq(1)
    expect(result.dig(:profile_version, :profile)).to eq("skills" => [ "Ruby", "Rails" ])
  end

  it "creates immutable, monotonically versioned profile snapshots backed by selected evidence" do
    candidate = WorkspaceContext.with(workspace) do
      described_class.create_candidate(first_name: "Ada", last_name: "Lovelace", profile: { skills: [ "Ruby" ] })
    end

    evidence = WorkspaceContext.with(workspace) do
      described_class.record_evidence(
        candidate_id: candidate.dig(:candidate, :id),
        source_type: "resume",
        source_reference: "resume:2026-09",
        claim: "Built a production Rails platform",
        confidence: 0.95,
        provenance: { document_digest: "abc123" }
      )
    end

    version = WorkspaceContext.with(workspace) do
      described_class.create_profile_version(
        candidate_id: candidate.dig(:candidate, :id),
        profile: { skills: [ "Ruby", "Rails" ], achievements: [ "Production platform" ] },
        evidence_ids: [ evidence.fetch(:id) ]
      )
    end

    expect(version.fetch(:version_number)).to eq(2)
    expect(version.fetch(:evidence_ids)).to contain_exactly(evidence.fetch(:id))
    expect(version.fetch(:content_digest)).to match(/\A[0-9a-f]{64}\z/)
    expect(version).to be_frozen
    expect(version.fetch(:profile)).to be_frozen

    record = WorkspaceContext.with(workspace) do
      TalentProfile::CandidateProfileVersion.find(TalentProfile::Identifiers.uuid(version.fetch(:id), prefix: "candidate_profile_version"))
    end

    expect { record.update!(profile_data: { skills: [ "Changed" ] }) }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { record.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
  end

  it "requires explicit user acceptance before agent-derived data becomes canonical" do
    candidate = WorkspaceContext.with(workspace) do
      described_class.create_candidate(first_name: "Grace", last_name: "Hopper")
    end

    expect do
      WorkspaceContext.with(workspace) do
        described_class.create_profile_version(
          candidate_id: candidate.dig(:candidate, :id),
          profile: { strengths: [ "Systems thinking" ] },
          origin: "agent_accepted"
        )
      end
    end.to raise_error(ArgumentError, /accepted_by_user_id is required/)

    accepted = WorkspaceContext.with(workspace, membership:) do
      described_class.create_profile_version(
        candidate_id: candidate.dig(:candidate, :id),
        profile: { strengths: [ "Systems thinking" ] },
        origin: "agent_accepted",
        accepted_by_user_id: user.typed_id
      )
    end

    expect(accepted.fetch(:origin)).to eq("agent_accepted")
    expect(accepted.fetch(:accepted_by_user_id)).to eq(user.typed_id)
    expect(accepted.fetch(:accepted_at)).to be_present
  end

  it "rejects cross-workspace Candidate access through the public API" do
    candidate = WorkspaceContext.with(workspace) do
      described_class.create_candidate(first_name: "Workspace", last_name: "One")
    end

    expect do
      WorkspaceContext.with(other_workspace) do
        described_class.fetch_candidate(candidate_id: candidate.dig(:candidate, :id))
      end
    end.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "rejects linking a Candidate to a User who is not a member of the workspace" do
    expect do
      WorkspaceContext.with(other_workspace) do
        described_class.create_candidate(
          first_name: "Wrong",
          last_name: "Workspace",
          linked_user_id: user.typed_id
        )
      end
    end.to raise_error(ActiveRecord::InvalidForeignKey)
  end
end
