# frozen_string_literal: true

RSpec.shared_examples Integrations::Base::Discord do
  using RSpec::Parameterized::TableSyntax

  it_behaves_like "chat integration", "Discord notifications", supports_deployments: true do
    let(:webhook_url) { "https://discord.com/" }
    let(:client) { Gitlab::HTTP }
    let(:client_arguments) { webhook_url }
    let(:payload) do
      {
        content: '',
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

  describe 'Validations' do
    let_it_be(:project) { create(:project) }

    subject(:discord_integration) { build(:discord_integration, project: project) }

    describe 'webhook fields' do
      shared_examples 'a validated discord webhook url' do |url_field|
        where(:webhook_url, :is_valid) do
          'http://discord.com/' | false
          'https://not-discord.com/' | false
          'https://badsite.com/query?url=discord.com' | false
          'https://badsite.com/discord.com/api/webhooks/12345/token_12-34' | false
          'https://discord.com.bad.com/api/webhooks/12345/token_12-34' | false
          'https://discord.company.xyz/api/webhooks/12345/token_12-34' | false
          'https://discord.com' | true
          'https://discord.com/' | true
          'https://discord.com/api/webhooks/12345/token_12-34' | true
          'https://discord.com/api/webhooks/12345/token_12-34?thread_id=1234' | true
        end

        with_them do
          subject(:discord_integration) { build(:discord_integration, project: project, "#{url_field}": webhook_url) }

          context 'when the integration is new' do
            it "validates #{url_field} when active" do
              expect(discord_integration.valid?).to eq(is_valid)
            end

            it "does not validate #{url_field} when inactive" do
              discord_integration.active = false

              expect(discord_integration).to be_valid
            end
          end

          context 'when the integration already exists' do
            it "does not validate #{url_field} on existing active integrations when webhook is not changed" do
              discord_integration.save!(validate: false)

              expect(discord_integration).to be_valid
            end

            it "validates #{url_field} on active integrations that previously had valid webhooks" do
              discord_integration.public_send(:"#{url_field}=", 'https://discord.com/api/webhooks/12345/token_12-34')
              discord_integration.save!
              discord_integration.public_send(:"#{url_field}=", webhook_url)

              expect(discord_integration.valid?).to eq(is_valid)
            end

            it "validates #{url_field} on previously inactive integrations when activated" do
              discord_integration.active = false
              discord_integration.save!
              discord_integration.active = true

              expect(discord_integration.valid?).to eq(is_valid)
            end

            it "does not validate #{url_field} on integrations when deactivated" do
              discord_integration.save!(validate: false)
              discord_integration.active = false

              expect(discord_integration).to be_valid
            end
          end
        end
      end

      context 'when validating webhook' do
        it_behaves_like 'a validated discord webhook url', 'webhook'
      end

      context 'when validating an event channel attribute' do
        it { is_expected.to allow_value(nil).for(:note_channel) }
        it { is_expected.to allow_value('   ').for(:note_channel) }

        it 'does not allow multiple valid webhook overrides' do
          is_expected.not_to allow_value(
            'https://discord.com/api/webhooks/12345/token_12-34,https://discord.com/api/webhooks/6789/token_56-78'
          ).for(:note_channel)
        end

        it 'validates note_channel when it was previously blank' do
          # This isn't a valid case for `webhook` because it's a required field, but channel fields can be
          # nil so it's necessary to validate those any time they go from nil (not a valid URL) to anything
          discord_integration.save!
          discord_integration.note_channel = 'http://not-discord.com'

          expect(discord_integration).not_to be_valid
          expect(discord_integration.errors.full_messages).to include(
            'Note channel URL must point to discord.com',
            'Note channel is blocked: Only allowed schemes are https'
          )
        end

        it_behaves_like 'a validated discord webhook url', 'note_channel'
      end
    end
  end

  describe '.help' do
    it 'links to help page correctly' do
      expect(described_class.help).to include(
        'user/project/integrations/discord_notifications.md',
        'How do I set up this integration?'
      )
    end
  end

  describe '#execute' do
    include StubRequests

    let_it_be(:project) { create(:project, :repository) }

    let(:user) { build_stubbed(:user) }
    let(:webhook_url) { "https://discord.com/" }
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

    it 'calls the webhook URL using Gitlab:::HTTP' do
      expect(Gitlab::HTTP).to receive(:post).with(
        webhook_url,
        headers: { 'Content-Type' => 'application/json' },
        body: an_instance_of(String)
      ).and_call_original

      discord_integration.execute(sample_data)
    end

    it 'uses the right embed parameters' do
      freeze_time do
        discord_integration.execute(sample_data)

        expect(WebMock).to have_requested(:post, webhook_url).with { |request|
          branch_link = "[master](http://localhost/#{project.namespace.path}/#{project.path}/-/commits/master)"
          embeds = Gitlab::Json.parse(request.body).with_indifferent_access[:embeds]

          expect(embeds).to match(
            [a_hash_including(
              description: start_with("#{user.name} pushed to branch #{branch_link} of"),
              author: {
                icon_url: start_with('https://www.gravatar.com/avatar/'),
                name: user.name
              },
              color: 3359829,
              timestamp: Time.now.utc.iso8601
            )]
          )
        }.once
      end
    end

    context 'when description references attachments' do
      let(:attachments) { ": foo\n - bar" }

      before do
        allow_next_instance_of(Integrations::ChatMessage::PushMessage) do |message|
          allow(message).to receive_messages(pretext: 'pretext', attachments: attachments)
        end
      end

      it 'updates attachment format' do
        freeze_time do
          discord_integration.execute(sample_data)

          expect(WebMock).to have_requested(:post, webhook_url).with { |request|
            embeds = Gitlab::Json.parse(request.body).with_indifferent_access[:embeds]

            expect(embeds.first[:description]).to eq("pretext\n foo - bar\n")
          }.once
        end
      end

      context 'when description is large' do
        let(:attachments) { "#{': -' * 20_000}: foo\n - bar" }

        it 'updates attachment format' do
          Timeout.timeout(1) do
            freeze_time do
              discord_integration.execute(sample_data)

              expect(WebMock).to have_requested(:post, webhook_url).with { |request|
                embeds = Gitlab::Json.parse(request.body).with_indifferent_access[:embeds]

                expect(embeds.first[:description]).to eq("pretext\n#{' -:' * 20_000} foo - bar\n")
              }.once
            end
          end
        end
      end
    end

    context 'when the Discord request fails' do
      before do
        WebMock.stub_request(:post, webhook_url).to_return(status: 401)
      end

      it 'logs an error and returns false' do
        expect(discord_integration).to receive(:log_error).with(
          'Error notifying Discord', { response_code: 401, response_body: '' }
        )
        expect(discord_integration.execute(sample_data)).to be(false)
      end
    end
  end
end
