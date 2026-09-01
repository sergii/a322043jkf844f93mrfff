# frozen_string_literal: true

require "rails_helper"

RSpec.describe Acquisition::RecordSourceObservation, type: :model do
  let(:observed_at) { Time.zone.parse("2026-09-01 12:34:56.123456") }
  let(:attributes) do
    {
      source_key: "dou",
      transport: "http_scrape",
      external_id: "jobs/123",
      canonical_url: "https://jobs.dou.ua/companies/example/vacancies/123/",
      observed_at:,
      payload: {
        "title" => "Senior Ruby Engineer",
        "company" => "Example"
      },
      metadata: { "collector" => "dou-v1" }
    }
  end

  it "records an immutable source fact with a typed identifier" do
    observation = nil

    expect do
      observation = described_class.call(**attributes)
    end.to change(SourceObservation, :count).by(1)

    expect(observation).to have_attributes(
      source_key: "dou",
      transport: "http_scrape",
      external_id: "jobs/123",
      observed_at:
    )
    expect(observation.typed_id).to start_with("source_observation_")
    expect(observation.content_digest).to match(/\A[0-9a-f]{64}\z/)
    expect(observation.idempotency_key).to match(/\A[0-9a-f]{64}\z/)
    expect(observation).to be_readonly
    expect { observation.update!(external_id: "jobs/changed") }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "deduplicates a retry of the same observation" do
    first = described_class.call(**attributes)

    expect do
      second = described_class.call(**attributes)
      expect(second.id).to eq(first.id)
    end.not_to change(SourceObservation, :count)
  end

  it "canonicalizes JSON object ordering for content identity" do
    first = described_class.call(**attributes)
    reordered = attributes.merge(payload: { "company" => "Example", "title" => "Senior Ruby Engineer" })

    second = described_class.call(**reordered)

    expect(second.id).to eq(first.id)
    expect(second.content_digest).to eq(first.content_digest)
  end

  it "keeps a later observation even when source content is unchanged" do
    first = described_class.call(**attributes)

    expect do
      second = described_class.call(**attributes.merge(observed_at: observed_at + 5.minutes))
      expect(second.id).not_to eq(first.id)
    end.to change(SourceObservation, :count).by(1)
  end
end
