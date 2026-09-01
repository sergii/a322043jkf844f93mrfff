# frozen_string_literal: true

require "digest"

module Acquisition
  class RecordSourceObservation
    class IdempotencyConflict < StandardError; end

    class << self
      def call(source_key:, transport:, observed_at:, payload:, external_id: nil, canonical_url: nil, metadata: {})
        new(
          source_key:,
          transport:,
          observed_at:,
          payload:,
          external_id:,
          canonical_url:,
          metadata:
        ).call
      end
    end

    def initialize(source_key:, transport:, observed_at:, payload:, external_id:, canonical_url:, metadata:)
      @source_key = source_key.to_s.strip.downcase
      @transport = transport.to_s.strip.downcase
      @observed_at = observed_at
      @payload = payload
      @external_id = external_id.to_s.strip.presence
      @canonical_url = canonical_url.to_s.strip.presence
      @metadata = metadata
    end

    def call
      attributes = observation_attributes
      observation = find_or_create_observation(attributes)

      return observation if same_observation?(observation, attributes)

      raise IdempotencyConflict, "idempotency key already belongs to a different source observation"
    end

    private

    attr_reader :source_key, :transport, :observed_at, :payload, :external_id, :canonical_url, :metadata

    def find_or_create_observation(attributes)
      idempotency_key = attributes.fetch(:idempotency_key)

      SourceObservation.find_by(idempotency_key:) || create_observation(attributes)
    end

    def create_observation(attributes)
      SourceObservation.create!(attributes)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => error
      # Another worker may have persisted the same immutable observation after
      # our initial lookup. Return that row only when the idempotency key now
      # exists; otherwise preserve the original validation/database failure.
      SourceObservation.find_by(idempotency_key: attributes.fetch(:idempotency_key)) || raise(error)
    end

    def observation_attributes
      @observation_attributes ||= {
        source_key:,
        transport:,
        external_id:,
        canonical_url:,
        observed_at: normalized_observed_at,
        content_digest:,
        idempotency_key:,
        payload:,
        metadata:
      }
    end

    def normalized_observed_at
      @normalized_observed_at ||= observed_at.respond_to?(:in_time_zone) ? observed_at.in_time_zone : Time.zone.parse(observed_at.to_s)
    end

    def content_digest
      @content_digest ||= Digest::SHA256.hexdigest(canonical_json(payload))
    end

    def idempotency_key
      @idempotency_key ||= Digest::SHA256.hexdigest(
        [
          source_key,
          transport,
          external_id,
          canonical_url,
          normalized_observed_at.iso8601(6),
          content_digest
        ].join("|")
      )
    end

    def canonical_json(value)
      JSON.generate(canonicalize(value))
    end

    def canonicalize(value)
      case value
      when Hash
        value.to_h.transform_keys(&:to_s).sort.to_h.transform_values { canonicalize(_1) }
      when Array
        value.map { canonicalize(_1) }
      else
        value
      end
    end

    def same_observation?(observation, attributes)
      observation.source_key == attributes.fetch(:source_key) &&
        observation.transport == attributes.fetch(:transport) &&
        observation.external_id == attributes[:external_id] &&
        observation.canonical_url == attributes[:canonical_url] &&
        observation.observed_at == attributes.fetch(:observed_at) &&
        observation.content_digest == attributes.fetch(:content_digest)
    end
  end
end
