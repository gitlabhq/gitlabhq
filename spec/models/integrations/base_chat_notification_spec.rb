# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::BaseChatNotification do
  describe 'Associations' do
    before do
      allow(subject).to receive(:activated?).and_return(true)
    end

    it { is_expected.to validate_presence_of :webhook }
  end

  describe 'validations' do
    it { is_expected.to validate_inclusion_of(:labels_to_be_notified_behavior).in_array(%w[match_any match_all]).allow_blank }
  end

  describe '#can_test?' do
    context 'with empty repository' do
      it 'returns true' do
        subject.project = create(:project, :empty_repo)

        expect(subject.can_test?).to be true
      end
    end

    context 'with repository' do
      it 'returns true' do
        subject.project = create(:project, :repository)

        expect(subject.can_test?).to be true
      end
    end
  end

  describe '#execute' do
    subject(:chat_integration) { described_class.new }

    let_it_be(:project) { create(:project, :repository) }

    let(:user) { create(:user) }
    let(:webhook_url) { 'https://example.gitlab.com/' }
    let(:data) { Gitlab::DataBuilder::Push.build_sample(subject.project, user) }

    before do
      allow(chat_integration).to receive_messages(
        project: project,
        project_id: project.id,
        service_hook: true,
        webhook: webhook_url
      )

      WebMock.stub_request(:post, webhook_url)

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
        subject.project = create(:project, :empty_repo)

        expect(chat_integration).to receive(:notify).and_return(true)
        expect(chat_integration.execute(data)).to be true
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
      let_it_be(:label) { create(:label, name: 'Bug') }
      let_it_be(:label_2) { create(:label, name: 'Community contribution') }
      let_it_be(:label_3) { create(:label, name: 'Backend') }
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
          let(:data) { create(:merge_request, labels: [label]).to_hook_data(user) }

          it_behaves_like 'notifies the chat integration'
        end

        context 'Issue events' do
          let(:data) { issue.to_hook_data(user) }

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
  end
end
