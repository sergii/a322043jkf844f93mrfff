# frozen_string_literal: true

require "json"

namespace :lmx do
  namespace :acquisition do
    desc "Acquire current DOU vacancies into durable Phase 0 evidence (RSS primary, HTML fallback)"
    task dou: :environment do
      result = Acquisition::Dou.collect(
        search: ENV["SEARCH"],
        strategy: ENV["STRATEGY"],
        run_key: ENV["RUN_KEY"],
        started_at: Time.current
      )

      puts JSON.pretty_generate(result.to_h)
    end
  end
end
