# frozen_string_literal: true

require "spec_helper"

describe DiscordService do
  it_behaves_like "chat service", "Discord notifications" do
    let(:client) { Discordrb::Webhooks::Client }
    let(:client_arguments) { { url: webhook_url } }
    let(:content_key) { :content }
  end
end
