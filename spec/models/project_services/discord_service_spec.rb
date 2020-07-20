# frozen_string_literal: true

require "spec_helper"

RSpec.describe DiscordService do
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

    it 'uses the right embed parameters' do
      builder = Discordrb::Webhooks::Builder.new

      allow_next_instance_of(Discordrb::Webhooks::Client) do |client|
        allow(client).to receive(:execute).and_yield(builder)
      end

      subject.execute(sample_data)

      expect(builder.to_json_hash[:embeds].first).to include(
        description: start_with("#{user.name} pushed to branch [master](http://localhost/#{project.namespace.path}/#{project.path}/commits/master) of"),
        author: hash_including(
          icon_url: start_with('https://www.gravatar.com/avatar/'),
          name: user.name
        )
      )
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
