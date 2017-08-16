require 'spec_helper'

describe PushoverService do
  describe 'Associations' do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    context 'when service is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:api_key) }
      it { is_expected.to validate_presence_of(:user_key) }
      it { is_expected.to validate_presence_of(:priority) }
    end

    context 'when service is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:api_key) }
      it { is_expected.not_to validate_presence_of(:user_key) }
      it { is_expected.not_to validate_presence_of(:priority) }
    end
  end

  describe 'Execute' do
    let(:pushover) { described_class.new }
    let(:user) { create(:user) }
    let(:project) { create(:project, :repository) }
    let(:sample_data) do
      Gitlab::DataBuilder::Push.build_sample(project, user)
    end

    let(:api_key) { 'verySecret' }
    let(:user_key) { 'verySecret' }
    let(:device) { 'myDevice' }
    let(:priority) { 0 }
    let(:sound) { 'bike' }
    let(:api_url) { 'https://api.pushover.net/1/messages.json' }

    before do
      allow(pushover).to receive_messages(
        project: project,
        project_id: project.id,
        service_hook: true,
        api_key: api_key,
        user_key: user_key,
        device: device,
        priority: priority,
        sound: sound
      )

      WebMock.stub_request(:post, api_url)
    end

    it 'calls Pushover API' do
      pushover.execute(sample_data)

      expect(WebMock).to have_requested(:post, api_url).once
    end
  end
end
