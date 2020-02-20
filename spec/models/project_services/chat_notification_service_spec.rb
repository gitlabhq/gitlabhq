# frozen_string_literal: true

require 'spec_helper'

describe ChatNotificationService do
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
  end
end
