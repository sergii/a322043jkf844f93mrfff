# frozen_string_literal: true

module Acquisition
  class QueryPolicy
    class << self
      def source_queries(source_id)
        queries = profile
          .fetch("acquisition", {})
          .fetch("source_queries", {})
          .fetch(source_id.to_s, [])

        queries.filter_map { _1.to_s.strip.presence }.uniq.freeze
      end

      private

      def profile
        Lmx::Configuration.default_profile
      end
    end
  end
end
