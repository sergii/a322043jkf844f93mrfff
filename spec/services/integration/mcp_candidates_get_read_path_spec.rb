# frozen_string_literal: true

require "rails_helper"

RSpec.describe "MCP candidates.get read path" do
  let(:context) do
    Integration::Mcp::ContextFactory.new.call(
      workspace_id: "workspace_opaque",
      principal: "user:serhii",
      credential: "credential_opaque",
      actor: "human:serhii",
      executor: "agent:generic",
      client: "generic-client",
      request_id: "request_opaque",
      correlation_id: "correlation_opaque"
    )
  end

  let(:candidate_api) do
    Class.new do
      attr_reader :candidate_ids

      def initialize
        @candidate_ids = []
      end

      def fetch_candidate(candidate_id:)
        @candidate_ids << candidate_id
        {
          id: candidate_id,
          first_name: "Ada",
          last_name: "Lovelace",
          profile_version: nil
        }
      end
    end.new
  end

  let(:workspace_scope) do
    Class.new do
      attr_reader :contexts

      def initialize
        @contexts = []
      end

      def call(context)
        @contexts << context
        yield
      end
    end.new
  end

  let(:capabilities) { [ "read:candidates" ] }
  let(:capability_resolver) do
    resolver_capabilities = capabilities

    Class.new do
      define_method(:initialize) do |allowed_capabilities|
        @allowed_capabilities = allowed_capabilities
      end

      define_method(:resolve) do |resolved_context|
        Integration::Read::CapabilityGrant.new(
          workspace_id: resolved_context.workspace_id,
          principal: resolved_context.principal,
          credential: resolved_context.credential,
          capabilities: @allowed_capabilities
        )
      end
    end.new(resolver_capabilities)
  end

  let(:candidate_query) do
    Integration::Read::Adapters::CandidatesGet.new(
      candidate_api:,
      workspace_scope:
    )
  end

  let(:query_router) do
    Integration::Read::QueryRouter.new(
      routes: { "candidates.get.v1" => candidate_query }
    )
  end

  let(:authorization_port) do
    Integration::Read::CapabilityAuthorization.new(capability_resolver:)
  end

  let(:dispatcher) do
    Integration::Read::Dispatcher.new(
      query_port: query_router,
      authorization_port:
    )
  end

  let(:adapter) { Integration::Mcp::ReadAdapter.new(dispatcher:) }

  it "executes the complete read path without exposing domain models to MCP" do
    candidate_id = "candidate_opaque"

    result = adapter.call(
      name: "candidates.get",
      arguments: { id: candidate_id },
      context:
    )

    expect(result[:isError]).to be(false)
    expect(result.dig(:structuredContent, :data)).to include(
      id: candidate_id,
      first_name: "Ada",
      last_name: "Lovelace"
    )
    expect(result.dig(:structuredContent, :meta, :provenance)).to eq(
      adapter: "talent_profile.public_api"
    )
    expect(result.dig(:structuredContent, :context)).to include(
      workspace_id: "workspace_opaque",
      actor: "human:serhii",
      executor: "agent:generic",
      interface: "mcp",
      client: "generic-client"
    )
    expect(candidate_api.candidate_ids).to eq([ candidate_id ])
    expect(workspace_scope.contexts).to eq([ context ])
  end

  context "without the required capability" do
    let(:capabilities) { [] }

    it "fails closed before entering workspace scope or calling the candidate API" do
      result = adapter.call(
        name: "candidates.get",
        arguments: { id: "candidate_opaque" },
        context:
      )

      expect(result[:isError]).to be(true)
      expect(result.dig(:structuredContent, :error, :code)).to eq("unauthorized")
      expect(candidate_api.candidate_ids).to be_empty
      expect(workspace_scope.contexts).to be_empty
    end
  end
end
