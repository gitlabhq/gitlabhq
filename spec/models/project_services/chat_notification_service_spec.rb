# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ChatNotificationService do
  describe 'Associations' do
    before do
      allow(subject).to receive(:activated?).and_return(true)
    end

    it { is_expected.to validate_presence_of :webhook }
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
    subject(:chat_service) { described_class.new }

    let(:user) { create(:user) }
    let(:project) { create(:project, :repository) }
    let(:webhook_url) { 'https://example.gitlab.com/' }
    let(:data) { Gitlab::DataBuilder::Push.build_sample(subject.project, user) }

    before do
      allow(chat_service).to receive_messages(
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
        expect(chat_service).to receive(:notify).and_return(true)
        expect(chat_service.execute(data)).to be true
      end
    end

    context 'with an empty repository' do
      it 'returns true' do
        subject.project = create(:project, :empty_repo)

        expect(chat_service).to receive(:notify).and_return(true)
        expect(chat_service.execute(data)).to be true
      end
    end

    context 'with a project with name containing spaces' do
      it 'does not remove spaces' do
        allow(project).to receive(:full_name).and_return('Project Name')

        expect(chat_service).to receive(:get_message).with(any_args, hash_including(project_name: 'Project Name'))
        chat_service.execute(data)
      end
    end

    context 'with "channel" property' do
      before do
        allow(chat_service).to receive(:channel).and_return(channel)
      end

      context 'empty string' do
        let(:channel) { '' }

        it 'does not include the channel' do
          expect(chat_service).to receive(:notify).with(any_args, hash_excluding(:channel)).and_return(true)
          expect(chat_service.execute(data)).to be(true)
        end
      end

      context 'empty spaces' do
        let(:channel) { '  ' }

        it 'does not include the channel' do
          expect(chat_service).to receive(:notify).with(any_args, hash_excluding(:channel)).and_return(true)
          expect(chat_service.execute(data)).to be(true)
        end
      end
    end

    shared_examples 'with channel specified' do |channel, expected_channels|
      before do
        allow(chat_service).to receive(:push_channel).and_return(channel)
      end

      it 'notifies all channels' do
        expect(chat_service).to receive(:notify).with(any_args, hash_including(channel: expected_channels)).and_return(true)
        expect(chat_service.execute(data)).to be(true)
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
