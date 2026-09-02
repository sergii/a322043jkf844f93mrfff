# frozen_string_literal: true

module Intelligence
  module Api
    class Error < StandardError; end
    class InvalidInput < Error; end
    class NotFound < Error; end
    class ContractViolation < Error; end

    module_function

    def record_match_assessment(**attributes)
      assessment_snapshot(RecordMatchAssessment.call(**attributes))
    rescue RecordMatchAssessment::InvalidInput, ActiveRecord::RecordInvalid => error
      raise InvalidInput, error.message
    rescue RecordMatchAssessment::ContractViolation => error
      raise ContractViolation, error.message
    rescue TalentProfile::Api::NotFound, MarketCatalog::Api::NotFound
      raise NotFound, "assessment input not found"
    end

    def fetch_match_assessment(workspace_id:, assessment_id:)
      workspace_uuid = Identifiers.uuid(workspace_id, prefix: "org")
      assessment_uuid = Identifiers.uuid(assessment_id, prefix: "match_assessment")
      assessment = MatchAssessment.find_by!(organization_id: workspace_uuid, id: assessment_uuid)

      assessment_snapshot(assessment)
    rescue ArgumentError, ActiveRecord::RecordNotFound
      raise NotFound, "match assessment not found"
    end

    def fetch_latest_match(workspace_id:, candidate_id:, job_opening_id:)
      workspace_uuid = Identifiers.uuid(workspace_id, prefix: "org")
      assessment = MatchAssessment
        .where(organization_id: workspace_uuid, candidate_id:, job_opening_id:)
        .order(version_number: :desc)
        .first!

      assessment_snapshot(assessment)
    rescue ArgumentError, ActiveRecord::RecordNotFound
      raise NotFound, "match assessment not found"
    end

    def assessment_snapshot(assessment)
      {
        id: assessment.typed_id,
        workspace_id: TypeID.from_uuid("org", assessment.organization_id).to_s,
        candidate_id: assessment.candidate_id,
        candidate_profile_version_id: assessment.candidate_profile_version_id,
        candidate_profile_content_digest: assessment.candidate_profile_content_digest,
        job_opening_id: assessment.job_opening_id,
        opening_evidence_cutoff: assessment.opening_evidence_cutoff,
        opening_snapshot: deep_freeze(assessment.opening_snapshot.deep_dup),
        version_number: assessment.version_number,
        opportunity_score: assessment.opportunity_score&.to_f,
        action_priority: assessment.action_priority&.to_f,
        score_details: deep_freeze(assessment.score_details.deep_dup),
        strengths: deep_freeze(assessment.strengths.deep_dup),
        gaps: deep_freeze(assessment.gaps.deep_dup),
        risks: deep_freeze(assessment.risks.deep_dup),
        recommendation: assessment.recommendation,
        interview_angles: deep_freeze(assessment.interview_angles.deep_dup),
        evidence_references: deep_freeze(assessment.evidence_references.deep_dup),
        scoring_policy_version: assessment.scoring_policy_version,
        processor: compact_frozen_hash(
          kind: assessment.processor_kind,
          key: assessment.processor_key,
          version: assessment.processor_version,
          model_name: assessment.processor_model_name,
          model_version: assessment.model_version
        ),
        generated_at: assessment.generated_at,
        created_at: assessment.created_at
      }.freeze
    end
    private_class_method :assessment_snapshot

    def compact_frozen_hash(**attributes)
      attributes.compact.freeze
    end
    private_class_method :compact_frozen_hash

    def deep_freeze(value)
      case value
      when Hash
        value.each { |key, nested| key.freeze; deep_freeze(nested) }
      when Array
        value.each { deep_freeze(_1) }
      end
      value.freeze
    end
    private_class_method :deep_freeze
  end
end
