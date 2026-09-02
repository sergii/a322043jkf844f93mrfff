# frozen_string_literal: true

require "rails_helper"
require "yaml"

RSpec.describe AcquisitionCollectionJob, type: :job do
  it "routes supported sources through their public acquisition APIs" do
    allow(Acquisition::Dou).to receive(:collect).and_return(:dou_result)
    allow(Acquisition::Djinni).to receive(:collect).and_return(:djinni_result)
    allow(Acquisition::WorkUa).to receive(:collect).and_return(:work_ua_result)
    allow(Acquisition::RobotaUa).to receive(:collect).and_return(:robota_result)

    expect(described_class.new.perform("dou")).to eq(:dou_result)
    expect(described_class.new.perform("djinni")).to eq(:djinni_result)
    expect(described_class.new.perform("work_ua")).to eq(:work_ua_result)
    expect(described_class.new.perform("robota_ua")).to eq(:robota_result)
    expect(Acquisition::Dou).to have_received(:collect).once
    expect(Acquisition::Djinni).to have_received(:collect).once
    expect(Acquisition::WorkUa).to have_received(:collect).once
    expect(Acquisition::RobotaUa).to have_received(:collect).once
  end

  it "fails explicitly for an unsupported source" do
    expect { described_class.new.perform("missing") }
      .to raise_error(ArgumentError, /unsupported acquisition source/)
  end

  it "schedules only sources with an explicit unattended collection policy in production" do
    production = YAML.safe_load_file(
      Rails.root.join("config/recurring.yml"),
      aliases: true
    ).fetch("production")

    expect(production.fetch("acquisition_dou")).to eq(
      "class" => "AcquisitionCollectionJob",
      "queue" => "acquisition",
      "args" => [ "dou" ],
      "schedule" => "every 10 minutes"
    )
    expect(production.fetch("acquisition_djinni")).to eq(
      "class" => "AcquisitionCollectionJob",
      "queue" => "acquisition",
      "args" => [ "djinni" ],
      "schedule" => "every 10 minutes"
    )
    expect(production).not_to have_key("acquisition_work_ua")
    expect(production).not_to have_key("acquisition_robota_ua")
  end
end
