# frozen_string_literal: true

class DeliveryOutboxJob < ApplicationJob
  queue_as :delivery

  def perform(workspace_id: ENV["LMX_PHASE0_WORKSPACE_ID"])
    workspace_id = workspace_id.to_s.strip
    token = ENV["TELEGRAM_BOT_TOKEN"].to_s.strip
    chat_id = ENV["TELEGRAM_CHAT_ID"].to_s.strip
    return if workspace_id.blank? || token.blank? || chat_id.blank?

    Workspace::Api.with_workspace(workspace_id:) do
      Delivery::Telegram::Publisher.call(
        client: Delivery::Telegram::Client.new(token:, chat_id:)
      )
    end
  end
end
