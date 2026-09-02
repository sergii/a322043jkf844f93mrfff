# frozen_string_literal: true

module Acquisition
  module WorkUa
    SOURCE_KEY = "work_ua"
    COLLECTOR_VERSION = "work-ua-collector-v1"
    ADAPTER_VERSIONS = {
      "http_html" => "work-ua-html-v1"
    }.freeze
    PARSER_VERSIONS = {
      "http_html" => "work-ua-html-v1"
    }.freeze

    Result = Data.define(
      :source_run_id,
      :status,
      :strategy,
      :request_url,
      :fetched_count,
      :discovered_count,
      :observed_count,
      :raw_payload_ids,
      :ingestion_record_ids,
      :observation_ids
    )

    class RunFailed < StandardError; end

    class << self
      def collect(
        search: nil,
        strategy: nil,
        run_key: nil,
        started_at: Time.current,
        http_client: nil,
        parser: nil,
        clock: -> { Time.current }
      )
        Collector.call(
          search:,
          strategy:,
          run_key:,
          started_at:,
          http_client: http_client || HttpClient.new,
          parser:,
          clock:
        )
      end
    end
  end
end
