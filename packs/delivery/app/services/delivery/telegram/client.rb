# frozen_string_literal: true

require "json"
require "net/http"

module Delivery
  module Telegram
    class Client
      class Error < StandardError; end

      API_BASE = "https://api.telegram.org"

      def initialize(token:, chat_id:, api_base: API_BASE)
        @token = token.to_s
        @chat_id = chat_id.to_s
        @api_base = api_base.to_s
      end

      def send_message(text:)
        uri = URI("#{api_base}/bot#{token}/sendMessage")
        response = Net::HTTP.post(
          uri,
          JSON.generate(chat_id:, text:),
          "Content-Type" => "application/json"
        )
        return true if response.is_a?(Net::HTTPSuccess)

        raise Error, "Telegram sendMessage failed with HTTP #{response.code}"
      end

      private

      attr_reader :token, :chat_id, :api_base
    end
  end
end
