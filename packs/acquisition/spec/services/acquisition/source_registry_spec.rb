# frozen_string_literal: true

require "rails_helper"

RSpec.describe Acquisition::SourceRegistry, type: :model do
  it "exposes configured source identifiers and acquisition strategies" do
    expect(described_class.source_ids).to eq([ "dou", "djinni", "work_ua", "robota_ua", "remoteok" ])
    expect(described_class.enabled?("dou")).to be(true)
    expect(described_class.enabled?("djinni")).to be(true)
    expect(described_class.enabled?("work_ua")).to be(true)
    expect(described_class.enabled?("robota_ua")).to be(true)
    expect(described_class.enabled?("remoteok")).to be(true)
    expect(described_class.acquisition_strategies("dou")).to eq(
      [
        { "type" => "rss", "preference" => "primary", "status" => "active" },
        { "type" => "http_html", "preference" => "fallback", "status" => "active" },
        { "type" => "browser", "preference" => "fallback", "status" => "evaluate" }
      ]
    )
    expect(described_class.primary_strategy("dou")).to eq(
      "type" => "rss",
      "preference" => "primary",
      "status" => "active"
    )
    expect(described_class.primary_strategy("djinni")).to eq(
      "type" => "rss",
      "preference" => "primary",
      "status" => "active"
    )
    expect(described_class.primary_strategy("work_ua")).to eq(
      "type" => "http_html",
      "preference" => "primary",
      "status" => "active"
    )
    expect(described_class.primary_strategy("robota_ua")).to eq(
      "type" => "http_api",
      "preference" => "primary",
      "status" => "active"
    )
    expect(described_class.primary_strategy("remoteok")).to eq(
      "type" => "http_api",
      "preference" => "primary",
      "status" => "active"
    )
  end

  it "keeps personal ranking policy out of source metadata" do
    expect(described_class.fetch("dou")).not_to have_key("weight")
    expect(described_class.fetch("dou")).not_to have_key("lane")
    expect(described_class.fetch("djinni")).not_to have_key("weight")
    expect(described_class.fetch("djinni")).not_to have_key("lane")
    expect(described_class.fetch("work_ua")).not_to have_key("weight")
    expect(described_class.fetch("work_ua")).not_to have_key("lane")
    expect(described_class.fetch("robota_ua")).not_to have_key("weight")
    expect(described_class.fetch("robota_ua")).not_to have_key("lane")
    expect(described_class.fetch("remoteok")).not_to have_key("weight")
    expect(described_class.fetch("remoteok")).not_to have_key("lane")
  end

  it "fails explicitly for an unknown source" do
    expect { described_class.fetch("missing") }
      .to raise_error(KeyError, /Unknown acquisition source/)
  end
end
