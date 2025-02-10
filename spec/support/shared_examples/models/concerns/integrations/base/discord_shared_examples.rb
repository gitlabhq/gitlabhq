# frozen_string_literal: true

RSpec.shared_examples Integrations::Base::Discord do
  it_behaves_like "chat integration", "Discord notifications", supports_deployments: true do
    let(:client) { Discordrb::Webhooks::Client }
    let(:client_arguments) { { url: webhook_url } }
    let(:payload) do
      {
        embeds: [
          include(
            author: include(name: be_present),
            description: be_present,
            color: be_present,
            timestamp: be_present
          )
        ]
      }
    end

    it_behaves_like 'supports group mentions', :discord_integration
  end

  describe 'validations' do
    let_it_be(:project) { create(:project) }

    subject(:discord_integration) { integration }

    describe 'only allows one channel on events' do
      context 'when given more than one channel' do
        let(:integration) { build(:discord_integration, project: project, note_channel: 'webhook1,webhook2') }

        it { is_expected.not_to be_valid }
      end

      context 'when given one channel' do
        let(:integration) { build(:discord_integration, project: project, note_channel: 'webhook1') }

        it { is_expected.to be_valid }
      end
    end
  end

  describe '#execute' do
    include StubRequests

    let_it_be(:project) { create(:project, :repository) }

    let(:user) { build_stubbed(:user) }
    let(:webhook_url) { "https://example.gitlab.com/" }
    let(:sample_data) do
      Gitlab::DataBuilder::Push.build_sample(project, user)
    end

    subject(:discord_integration) { described_class.new }

    before do
      allow(discord_integration).to receive_messages(
        project: project,
        project_id: project.id,
        webhook: webhook_url
      )

      WebMock.stub_request(:post, webhook_url)
    end

    it 'uses the right embed parameters' do
      builder = Discordrb::Webhooks::Builder.new

      allow_next_instance_of(Discordrb::Webhooks::Client) do |client|
        allow(client).to receive(:execute).and_yield(builder)
      end

      expected_description = "#{user.name} pushed to branch " \
        "[master](http://localhost/#{project.namespace.path}/#{project.path}/-/commits/master) of"

      freeze_time do
        discord_integration.execute(sample_data)

        expect(builder.to_json_hash[:embeds].first).to include(
          description: start_with(expected_description),
          author: hash_including(
            icon_url: start_with('https://www.gravatar.com/avatar/'),
            name: user.name
          ),
          color: 3359829,
          timestamp: Time.now.utc.iso8601
        )
      end
    end

    context 'when description references attachments' do
      let(:builder) { Discordrb::Webhooks::Builder.new }
      let(:attachments) { ": foo\n - bar" }

      before do
        allow_next_instance_of(Discordrb::Webhooks::Client) do |client|
          allow(client).to receive(:execute).and_yield(builder)
        end

        allow_next_instance_of(Integrations::ChatMessage::PushMessage) do |message|
          allow(message).to receive_messages(
            pretext: 'pretext',
            attachments: attachments
          )
        end
      end

      it 'updates attachment format' do
        freeze_time do
          discord_integration.execute(sample_data)

          expect(builder.to_json_hash[:embeds].first)
            .to include(description: "pretext\n foo - bar\n")
        end
      end

      context 'when description is large' do
        let(:attachments) { "#{': -' * 20_000}: foo\n - bar" }

        it 'updates attachment format' do
          Timeout.timeout(1) do
            freeze_time do
              discord_integration.execute(sample_data)

              expect(builder.to_json_hash[:embeds].first)
                .to include(description: "pretext\n#{' -:' * 20_000} foo - bar\n")
            end
          end
        end
      end
    end

    context 'when DNS rebound to local address' do
      before do
        stub_dns(webhook_url, ip_address: '192.168.2.120')
      end

      it 'does not allow DNS rebinding' do
        expect { discord_integration.execute(sample_data) }.to raise_error(ArgumentError, /is blocked/)
      end
    end

    context 'when the Discord request fails' do
      before do
        WebMock.stub_request(:post, webhook_url).to_return(status: 400)
      end

      it 'logs an error and returns false' do
        expect(discord_integration).to receive(:log_error).with('400 Bad Request')
        expect(discord_integration.execute(sample_data)).to be(false)
      end
    end
  end
end
