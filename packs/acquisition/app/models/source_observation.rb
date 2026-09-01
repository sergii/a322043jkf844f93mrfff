# frozen_string_literal: true

class SourceObservation < ApplicationRecord
  include TypedId

  TRANSPORTS = %w[
    rss
    http_api
    http_scrape
    browser_crawl
    webhook
    api_submission
    manual
    import
  ].freeze

  uses_typed_id "source_observation"

  normalizes :source_key, with: -> { _1.strip.downcase }
  normalizes :transport, with: -> { _1.strip.downcase }
  normalizes :external_id, :canonical_url, with: -> { _1.strip.presence }
  normalizes :content_digest, :idempotency_key, with: -> { _1.strip.downcase }

  validates :source_key, presence: true, format: { with: /\A[a-z0-9][a-z0-9_-]*\z/ }
  validates :transport, inclusion: { in: TRANSPORTS }
  validates :observed_at, presence: true
  validates :content_digest, presence: true, format: { with: /\A[0-9a-f]{64}\z/ }
  validates :idempotency_key, presence: true, uniqueness: true, format: { with: /\A[0-9a-f]{64}\z/ }
  validates :canonical_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true

  # Raw source observations are evidence. Corrections are represented by later
  # observations or downstream interpretation, never by rewriting source facts.
  def readonly?
    persisted?
  end
end
