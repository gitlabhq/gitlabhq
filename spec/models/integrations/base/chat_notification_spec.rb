# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Base::ChatNotification, feature_category: :integrations do
  let(:integration_class) do
    Class.new(Integration) do
      include Integrations::Base::ChatNotification
    end
  end

  subject(:integration) { integration_class.new }

  before do
    stub_const('TestIntegration', integration_class)
  end

  describe 'default values' do
    it { expect(integration.category).to eq(:chat) }
  end

  describe 'Validations' do
    before do
      integration.active = active

      allow(integration)
        .to receive_messages(default_channel_placeholder: 'placeholder', webhook_help: 'help')
    end

    def build_channel_list(count)
      (1..count).map { |i| "##{i}" }.join(',')
    end

    context 'when active' do
      let(:active) { true }

      it { is_expected.to validate_presence_of :webhook }
      it { is_expected.to allow_value(build_channel_list(10)).for(:push_channel) }
      it { is_expected.not_to allow_value(build_channel_list(11)).for(:push_channel) }

      it 'validates inclusion of labels' do
        is_expected
          .to validate_inclusion_of(:labels_to_be_notified_behavior)
          .in_array(%w[match_any match_all]).allow_blank
      end
    end

    context 'when inactive' do
      let(:active) { false }

      it { is_expected.not_to validate_presence_of :webhook }
      it { is_expected.to allow_value(build_channel_list(10)).for(:push_channel) }
      it { is_expected.to allow_value(build_channel_list(11)).for(:push_channel) }

      it 'does not validate inclusion of labels' do
        is_expected
          .not_to validate_inclusion_of(:labels_to_be_notified_behavior)
          .in_array(%w[match_any match_all]).allow_blank
      end
    end
  end

  describe '#execute' do
    let_it_be(:project) { create(:project, :repository) }

    let(:user) { build_stubbed(:user) }
    let(:webhook_url) { 'https://example.gitlab.com/' }
    let(:data) { Gitlab::DataBuilder::Push.build_sample(integration.project, user) }

    before do
      allow(integration).to receive_messages(
        project: project,
        project_id: project.id,
        webhook: webhook_url
      )

      WebMock.stub_request(:post, webhook_url) if webhook_url.present?

      integration.active = true
    end

    context 'with a repository' do
      it 'returns true' do
        expect(integration).to receive(:notify).and_return(true)
        expect(integration.execute(data)).to be true
      end
    end

    context 'with an empty repository' do
      it 'returns true' do
        integration.project = build_stubbed(:project, :empty_repo)

        expect(integration).to receive(:notify).and_return(true)
        expect(integration.execute(data)).to be true
      end
    end

    context 'when webhook is blank' do
      let(:webhook_url) { '' }

      it 'returns false' do
        expect(integration).not_to receive(:notify)
        expect(integration.execute(data)).to be false
      end

      context 'when webhook is not required' do
        it 'returns true' do
          allow(integration.class).to receive(:requires_webhook?).and_return(false)

          expect(integration).to receive(:notify).and_return(true)
          expect(integration.execute(data)).to be true
        end
      end
    end

    context 'when event is not supported' do
      it 'returns false' do
        allow(integration).to receive(:supported_events).and_return(['foo'])

        expect(integration).not_to receive(:notify)
        expect(integration.execute(data)).to be false
      end
    end

    context 'with a project with name containing spaces' do
      it 'does not remove spaces' do
        allow(project).to receive(:full_name).and_return('Project Name')

        expect(integration).to receive(:get_message).with(any_args, hash_including(project_name: 'Project Name'))
        integration.execute(data)
      end
    end

    context 'when the data object has a label' do
      let_it_be(:label) { build(:label, project: project, name: 'Bug') }
      let_it_be(:label_2) { build(:label, project: project, name: 'Community contribution') }
      let_it_be(:label_3) { build(:label, project: project, name: 'Backend') }
      let_it_be(:issue) { create(:labeled_issue, project: project, labels: [label, label_2, label_3]) }
      let_it_be(:note) { create(:note, noteable: issue, project: project) }

      let(:data) { Gitlab::DataBuilder::Note.build(note, user, :create) }

      shared_examples 'notifies the chat integration' do
        specify do
          expect(integration).to receive(:notify).with(any_args)

          integration.execute(data)
        end
      end

      shared_examples 'does not notify the chat integration' do
        specify do
          expect(integration).not_to receive(:notify).with(any_args)

          integration.execute(data)
        end
      end

      it_behaves_like 'notifies the chat integration'

      context 'with label filter' do
        subject(:integration) { integration_class.new(labels_to_be_notified: '~Bug') }

        it_behaves_like 'notifies the chat integration'

        context 'when MergeRequest events' do
          let(:data) { build_stubbed(:merge_request, source_project: project, labels: [label]).to_hook_data(user) }

          it_behaves_like 'notifies the chat integration'
        end

        context 'when Issue events' do
          let(:data) { issue.to_hook_data(user) }

          it_behaves_like 'notifies the chat integration'
        end

        context 'when Incident events' do
          let(:data) { issue.to_hook_data(user).merge!({ object_kind: 'incident' }) }

          it_behaves_like 'notifies the chat integration'
        end
      end

      context 'when labels_to_be_notified_behavior is not defined' do
        subject(:integration) { integration_class.new(labels_to_be_notified: label_filter) }

        context 'when no matching labels' do
          let(:label_filter) { '~some random label' }

          it_behaves_like 'does not notify the chat integration'
        end

        context 'when only one label matches' do
          let(:label_filter) { '~some random label, ~Bug' }

          it_behaves_like 'notifies the chat integration'
        end
      end

      context 'when labels_to_be_notified_behavior is blank' do
        subject(:integration) do
          integration_class.new(
            labels_to_be_notified: label_filter,
            labels_to_be_notified_behavior: ''
          )
        end

        context 'when no matching labels' do
          let(:label_filter) { '~some random label' }

          it_behaves_like 'does not notify the chat integration'
        end

        context 'when only one label matches' do
          let(:label_filter) { '~some random label, ~Bug' }

          it_behaves_like 'notifies the chat integration'
        end
      end

      context 'when labels_to_be_notified_behavior is match_any' do
        subject(:integration) do
          integration_class.new(
            labels_to_be_notified: label_filter,
            labels_to_be_notified_behavior: 'match_any'
          )
        end

        context 'when no label filter' do
          let(:label_filter) { nil }

          it_behaves_like 'notifies the chat integration'
        end

        context 'when no matching labels' do
          let(:label_filter) { '~some random label' }

          it_behaves_like 'does not notify the chat integration'
        end

        context 'when only one label matches' do
          let(:label_filter) { '~some random label, ~Bug' }

          it_behaves_like 'notifies the chat integration'
        end
      end

      context 'when labels_to_be_notified_behavior is match_all' do
        subject(:integration) do
          integration_class.new(
            labels_to_be_notified: label_filter,
            labels_to_be_notified_behavior: 'match_all'
          )
        end

        context 'when no label filter' do
          let(:label_filter) { nil }

          it_behaves_like 'notifies the chat integration'
        end

        context 'when no matching labels' do
          let(:label_filter) { '~some random label' }

          it_behaves_like 'does not notify the chat integration'
        end

        context 'when only one label matches' do
          let(:label_filter) { '~some random label, ~Bug' }

          it_behaves_like 'does not notify the chat integration'
        end

        context 'when labels matches exactly' do
          let(:label_filter) { '~Bug, ~Backend, ~Community contribution' }

          it_behaves_like 'notifies the chat integration'
        end

        context 'when labels matches but object has more' do
          let(:label_filter) { '~Bug, ~Backend' }

          it_behaves_like 'notifies the chat integration'
        end

        context 'when labels are distributed on multiple objects' do
          let(:label_filter) { '~Bug, ~Backend' }
          let(:data) do
            Gitlab::DataBuilder::Note.build(note, user, :create).merge({
              issue: {
                labels: [
                  { title: 'Bug' }
                ]
              },
              merge_request: {
                labels: [
                  {
                    title: 'Backend'
                  }
                ]
              }
            })
          end

          it_behaves_like 'does not notify the chat integration'
        end
      end
    end

    context 'with "channel" property' do
      before do
        allow(integration).to receive(:channel).and_return(channel)
      end

      context 'when empty string' do
        let(:channel) { '' }

        it 'does not include the channel' do
          expect(integration)
            .to receive(:notify)
            .with(any_args, hash_excluding(:channel))
            .and_return(true)
          expect(integration.execute(data)).to be(true)
        end
      end

      context 'when empty spaces' do
        let(:channel) { '  ' }

        it 'does not include the channel' do
          expect(integration)
            .to receive(:notify)
            .with(any_args, hash_excluding(:channel))
            .and_return(true)
          expect(integration.execute(data)).to be(true)
        end
      end
    end

    shared_examples 'with channel specified' do |channel, expected_channels|
      before do
        allow(integration).to receive(:push_channel).and_return(channel)
      end

      it 'notifies all channels' do
        expect(integration)
          .to receive(:notify)
          .with(any_args, hash_including(channel: expected_channels))
          .and_return(true)
        expect(integration.execute(data)).to be(true)
      end
    end

    context 'with single channel specified' do
      it_behaves_like 'with channel specified', 'slack-integration', ['slack-integration']
    end

    context 'with multiple channel names specified' do
      it_behaves_like 'with channel specified',
        'slack-integration,#slack-test',
        ['slack-integration', '#slack-test']
    end

    context 'with multiple channel names with spaces specified' do
      it_behaves_like 'with channel specified',
        'slack-integration, #slack-test, @UDLP91W0A',
        ['slack-integration', '#slack-test', '@UDLP91W0A']
    end

    context 'with duplicate channel names' do
      it_behaves_like 'with channel specified',
        '#slack-test,#slack-test,#slack-test-2',
        ['#slack-test', '#slack-test-2']
    end
  end

  describe '#default_channel_placeholder' do
    it 'raises an error' do
      expect { integration.default_channel_placeholder }.to raise_error(NotImplementedError)
    end
  end

  describe '#webhook_help' do
    it 'raises an error' do
      expect { integration.webhook_help }.to raise_error(NotImplementedError)
    end
  end

  describe '#event_channel_name' do
    it 'returns the channel field name for the given event' do
      expect(integration.event_channel_name(:event)).to eq('event_channel')
    end
  end

  describe '#event_channel_value' do
    it 'returns the channel field value for the given event' do
      integration.push_channel = '#pushes'

      expect(integration.event_channel_value(:push)).to eq('#pushes')
    end

    it 'raises an error for unsupported events' do
      expect { integration.event_channel_value(:foo) }.to raise_error(NoMethodError)
    end
  end

  describe '#api_field_names' do
    context 'when channels are masked' do
      let(:project) { build(:project) }
      let(:integration) do
        integration_class.new(
          project: project,
          webhook: 'https://discord.com/api/',
          type: 'Integrations::Discord'
        )
      end

      it 'does not include channel properties', :aggregate_failures do
        integration.event_channel_names.each do |field|
          expect(integration.api_field_names).not_to include(field)
        end
      end
    end
  end
end
