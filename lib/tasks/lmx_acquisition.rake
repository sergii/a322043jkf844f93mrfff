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

    desc "Acquire current Djinni vacancies into durable Phase 0 evidence (RSS primary)"
    task djinni: :environment do
      result = Acquisition::Djinni.collect(
        search: ENV["SEARCH"],
        strategy: ENV["STRATEGY"],
        run_key: ENV["RUN_KEY"],
        started_at: Time.current
      )

      puts JSON.pretty_generate(result.to_h)
    end

    desc "Acquire current Work.ua vacancies into durable Phase 0 evidence (HTML primary)"
    task work_ua: :environment do
      result = Acquisition::WorkUa.collect(
        search: ENV["SEARCH"],
        strategy: ENV["STRATEGY"],
        run_key: ENV["RUN_KEY"],
        started_at: Time.current
      )

      puts JSON.pretty_generate(result.to_h)
    end

    desc "Acquire current Robota.ua vacancies into durable Phase 0 evidence (HTTP API primary)"
    task robota_ua: :environment do
      result = Acquisition::RobotaUa.collect(
        search: ENV["SEARCH"],
        strategy: ENV["STRATEGY"],
        run_key: ENV["RUN_KEY"],
        started_at: Time.current
      )

      puts JSON.pretty_generate(result.to_h)
    end

    desc "Print acquisition source health snapshots as JSON"
    task health: :environment do
      puts JSON.pretty_generate(Acquisition::SourceHealth.all.as_json)
    end
  end
end
