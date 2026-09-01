# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Gantt roadmap", type: :request do
  it "renders the isolated ReUI Gantt demo for the selected workspace" do
    user = User.create!(name: "Ada Lovelace", email: "gantt@example.com", password: "Password12345!", verified: true)
    organization = Organization.create!(name: "Roadmap workspace", slug: "roadmap-workspace")
    Membership.create!(user:, organization:, role: "recruiter")
    sign_in user

    get gantt_path

    expect(response).to have_http_status(:success)
    expect(inertia_component).to eq("gantt/index")
  end
end
