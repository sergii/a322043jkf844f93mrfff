# frozen_string_literal: true

require "rails_helper"

RSpec.describe Acquisition::SourceRegistry, type: :model do
  it "exposes configured source identifiers and acquisition strategies" do
    expect(described_class.source_ids).to eq([ "dou" ])
    expect(described_class.enabled?("dou")).to be(true)
    expect(described_class.acquisition_strategies("dou")).to eq(
      [
        { "type" => "http_html", "preference" => "primary", "status" => "evaluate" },
        { "type" => "browser", "preference" => "fallback", "status" => "evaluate" }
      ]
    )
    expect(described_class.primary_strategy("dou")).to eq(
      "type" => "http_html",
      "preference" => "primary",
      "status" => "evaluate"
    )
  end

  it "keeps personal ranking policy out of source metadata" do
    expect(described_class.fetch("dou")).not_to have_key("weight")
    expect(described_class.fetch("dou")).not_to have_key("lane")
  end

  it "fails explicitly for an unknown source" do
    expect { described_class.fetch("missing") }
      .to raise_error(KeyError, /Unknown acquisition source/)
  end
end
