# frozen_string_literal: true

RSpec.shared_examples Integrations::Base::Pushover do
  include StubRequests

  it_behaves_like Integrations::HasAvatar

  describe 'Validations' do
    context 'when integration is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:api_key) }
      it { is_expected.to validate_presence_of(:user_key) }
      it { is_expected.to validate_presence_of(:priority) }
    end

    context 'when integration is inactive' do
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
    let(:user) { build_stubbed(:user) }
    let(:project) { build_stubbed(:project, :repository) }
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
        api_key: api_key,
        user_key: user_key,
        device: device,
        priority: priority,
        sound: sound
      )

      stub_full_request(api_url, method: :post, ip_address: '8.8.8.8')
    end

    it 'calls Pushover API' do
      pushover.execute(sample_data)

      expect(WebMock).to have_requested(:post, 'https://8.8.8.8/1/messages.json').once
    end
  end
end
