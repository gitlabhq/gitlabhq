# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::BaseChatNotification, feature_category: :integrations do
  describe 'default values' do
    it { expect(subject.category).to eq(:chat) }
  end

  describe 'validations' do
    before do
      subject.active = active

      allow(subject).to receive(:default_channel_placeholder).and_return('placeholder')
      allow(subject).to receive(:webhook_help).and_return('help')
    end

    def build_channel_list(count)
      (1..count).map { |i| "##{i}" }.join(',')
    end

    context 'when active' do
      let(:active) { true }

      it { is_expected.to validate_presence_of :webhook }
      it { is_expected.to validate_inclusion_of(:labels_to_be_notified_behavior).in_array(%w[match_any match_all]).allow_blank }
      it { is_expected.to allow_value(build_channel_list(10)).for(:push_channel) }
      it { is_expected.not_to allow_value(build_channel_list(11)).for(:push_channel) }
    end

    context 'when inactive' do
      let(:active) { false }

      it { is_expected.not_to validate_presence_of :webhook }
      it { is_expected.not_to validate_inclusion_of(:labels_to_be_notified_behavior).in_array(%w[match_any match_all]).allow_blank }
      it { is_expected.to allow_value(build_channel_list(10)).for(:push_channel) }
      it { is_expected.to allow_value(build_channel_list(11)).for(:push_channel) }
    end
  end

  describe '#execute' do
    subject(:chat_integration) { described_class.new }

    let_it_be(:project) { create(:project, :repository) }

    let(:user) { build_stubbed(:user) }
    let(:webhook_url) { 'https://example.gitlab.com/' }
    let(:data) { Gitlab::DataBuilder::Push.build_sample(subject.project, user) }

    before do
      allow(chat_integration).to receive_messages(
        project: project,
        project_id: project.id,
        webhook: webhook_url
      )

      WebMock.stub_request(:post, webhook_url) if webhook_url.present?

      subject.active = true
    end

    context 'with a repository' do
      it 'returns true' do
        expect(chat_integration).to receive(:notify).and_return(true)
        expect(chat_integration.execute(data)).to be true
      end
    end

    context 'with an empty repository' do
      it 'returns true' do
        subject.project = build_stubbed(:project, :empty_repo)

        expect(chat_integration).to receive(:notify).and_return(true)
        expect(chat_integration.execute(data)).to be true
      end
    end

    context 'when webhook is blank' do
      let(:webhook_url) { '' }

      it 'returns false' do
        expect(chat_integration).not_to receive(:notify)
        expect(chat_integration.execute(data)).to be false
      end

      context 'when webhook is not required' do
        it 'returns true' do
          allow(chat_integration).to receive(:requires_webhook?).and_return(false)

          expect(chat_integration).to receive(:notify).and_return(true)
          expect(chat_integration.execute(data)).to be true
        end
      end
    end

    context 'when event is not supported' do
      it 'returns false' do
        allow(chat_integration).to receive(:supported_events).and_return(['foo'])

        expect(chat_integration).not_to receive(:notify)
        expect(chat_integration.execute(data)).to be false
      end
    end

    context 'with a project with name containing spaces' do
      it 'does not remove spaces' do
        allow(project).to receive(:full_name).and_return('Project Name')

        expect(chat_integration).to receive(:get_message).with(any_args, hash_including(project_name: 'Project Name'))
        chat_integration.execute(data)
      end
    end

    context 'when the data object has a label' do
      let_it_be(:label) { create(:label, project: project, name: 'Bug') }
      let_it_be(:label_2) { create(:label, project: project, name: 'Community contribution') }
      let_it_be(:label_3) { create(:label, project: project, name: 'Backend') }
      let_it_be(:issue) { create(:labeled_issue, project: project, labels: [label, label_2, label_3]) }
      let_it_be(:note) { create(:note, noteable: issue, project: project) }

      let(:data) { Gitlab::DataBuilder::Note.build(note, user) }

      shared_examples 'notifies the chat integration' do
        specify do
          expect(chat_integration).to receive(:notify).with(any_args)

          chat_integration.execute(data)
        end
      end

      shared_examples 'does not notify the chat integration' do
        specify do
          expect(chat_integration).not_to receive(:notify).with(any_args)

          chat_integration.execute(data)
        end
      end

      it_behaves_like 'notifies the chat integration'

      context 'with label filter' do
        subject(:chat_integration) { described_class.new(labels_to_be_notified: '~Bug') }

        it_behaves_like 'notifies the chat integration'

        context 'MergeRequest events' do
          let(:data) { build_stubbed(:merge_request, source_project: project, labels: [label]).to_hook_data(user) }

          it_behaves_like 'notifies the chat integration'
        end

        context 'Issue events' do
          let(:data) { issue.to_hook_data(user) }

          it_behaves_like 'notifies the chat integration'
        end

        context 'Incident events' do
          let(:data) { issue.to_hook_data(user).merge!({ object_kind: 'incident' }) }

          it_behaves_like 'notifies the chat integration'
        end
      end

      context 'when labels_to_be_notified_behavior is not defined' do
        subject(:chat_integration) { described_class.new(labels_to_be_notified: label_filter) }

        context 'no matching labels' do
          let(:label_filter) { '~some random label' }

          it_behaves_like 'does not notify the chat integration'
        end

        context 'only one label matches' do
          let(:label_filter) { '~some random label, ~Bug' }

          it_behaves_like 'notifies the chat integration'
        end
      end

      context 'when labels_to_be_notified_behavior is blank' do
        subject(:chat_integration) { described_class.new(labels_to_be_notified: label_filter, labels_to_be_notified_behavior: '') }

        context 'no matching labels' do
          let(:label_filter) { '~some random label' }

          it_behaves_like 'does not notify the chat integration'
        end

        context 'only one label matches' do
          let(:label_filter) { '~some random label, ~Bug' }

          it_behaves_like 'notifies the chat integration'
        end
      end

      context 'when labels_to_be_notified_behavior is match_any' do
        subject(:chat_integration) do
          described_class.new(
            labels_to_be_notified: label_filter,
            labels_to_be_notified_behavior: 'match_any'
          )
        end

        context 'no label filter' do
          let(:label_filter) { nil }

          it_behaves_like 'notifies the chat integration'
        end

        context 'no matching labels' do
          let(:label_filter) { '~some random label' }

          it_behaves_like 'does not notify the chat integration'
        end

        context 'only one label matches' do
          let(:label_filter) { '~some random label, ~Bug' }

          it_behaves_like 'notifies the chat integration'
        end
      end

      context 'when labels_to_be_notified_behavior is match_all' do
        subject(:chat_integration) do
          described_class.new(
            labels_to_be_notified: label_filter,
            labels_to_be_notified_behavior: 'match_all'
          )
        end

        context 'no label filter' do
          let(:label_filter) { nil }

          it_behaves_like 'notifies the chat integration'
        end

        context 'no matching labels' do
          let(:label_filter) { '~some random label' }

          it_behaves_like 'does not notify the chat integration'
        end

        context 'only one label matches' do
          let(:label_filter) { '~some random label, ~Bug' }

          it_behaves_like 'does not notify the chat integration'
        end

        context 'labels matches exactly' do
          let(:label_filter) { '~Bug, ~Backend, ~Community contribution' }

          it_behaves_like 'notifies the chat integration'
        end

        context 'labels matches but object has more' do
          let(:label_filter) { '~Bug, ~Backend' }

          it_behaves_like 'notifies the chat integration'
        end

        context 'labels are distributed on multiple objects' do
          let(:label_filter) { '~Bug, ~Backend' }
          let(:data) do
            Gitlab::DataBuilder::Note.build(note, user).merge({
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
        allow(chat_integration).to receive(:channel).and_return(channel)
      end

      context 'empty string' do
        let(:channel) { '' }

        it 'does not include the channel' do
          expect(chat_integration).to receive(:notify).with(any_args, hash_excluding(:channel)).and_return(true)
          expect(chat_integration.execute(data)).to be(true)
        end
      end

      context 'empty spaces' do
        let(:channel) { '  ' }

        it 'does not include the channel' do
          expect(chat_integration).to receive(:notify).with(any_args, hash_excluding(:channel)).and_return(true)
          expect(chat_integration.execute(data)).to be(true)
        end
      end
    end

    shared_examples 'with channel specified' do |channel, expected_channels|
      before do
        allow(chat_integration).to receive(:push_channel).and_return(channel)
      end

      it 'notifies all channels' do
        expect(chat_integration).to receive(:notify).with(any_args, hash_including(channel: expected_channels)).and_return(true)
        expect(chat_integration.execute(data)).to be(true)
      end
    end

    context 'with single channel specified' do
      it_behaves_like 'with channel specified', 'slack-integration', ['slack-integration']
    end

    context 'with multiple channel names specified' do
      it_behaves_like 'with channel specified', 'slack-integration,#slack-test', ['slack-integration', '#slack-test']
    end

    context 'with multiple channel names with spaces specified' do
      it_behaves_like 'with channel specified', 'slack-integration, #slack-test, @UDLP91W0A', ['slack-integration', '#slack-test', '@UDLP91W0A']
    end

    context 'with duplicate channel names' do
      it_behaves_like 'with channel specified', '#slack-test,#slack-test,#slack-test-2', ['#slack-test', '#slack-test-2']
    end
  end

  describe '#default_channel_placeholder' do
    it 'raises an error' do
      expect { subject.default_channel_placeholder }.to raise_error(NotImplementedError)
    end
  end

  describe '#webhook_help' do
    it 'raises an error' do
      expect { subject.webhook_help }.to raise_error(NotImplementedError)
    end
  end

  describe '#event_channel_name' do
    it 'returns the channel field name for the given event' do
      expect(subject.event_channel_name(:event)).to eq('event_channel')
    end
  end

  describe '#event_channel_value' do
    it 'returns the channel field value for the given event' do
      subject.push_channel = '#pushes'

      expect(subject.event_channel_value(:push)).to eq('#pushes')
    end

    it 'raises an error for unsupported events' do
      expect { subject.event_channel_value(:foo) }.to raise_error(NoMethodError)
    end
  end
end
