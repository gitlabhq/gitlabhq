# frozen_string_literal: true

require "spec_helper"

describe DiscordService do
  it_behaves_like "chat service", "Discord notifications" do
    let(:client) { Discordrb::Webhooks::Client }
    let(:client_arguments) { { url: webhook_url } }
    let(:content_key) { :content }
  end

  describe '#execute' do
    include StubRequests

    let(:user) { create(:user) }
    let(:project) { create(:project, :repository) }
    let(:webhook_url) { "https://example.gitlab.com/" }

    let(:sample_data) do
      Gitlab::DataBuilder::Push.build_sample(project, user)
    end

    before do
      allow(subject).to receive_messages(
        project: project,
        project_id: project.id,
        service_hook: true,
        webhook: webhook_url
      )

      WebMock.stub_request(:post, webhook_url)
    end

    context 'DNS rebind to local address' do
      before do
        stub_dns(webhook_url, ip_address: '192.168.2.120')
      end

      it 'does not allow DNS rebinding' do
        expect { subject.execute(sample_data) }.to raise_error(ArgumentError, /is blocked/)
      end
    end
  end
end
