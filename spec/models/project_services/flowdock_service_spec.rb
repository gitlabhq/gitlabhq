require 'spec_helper'

describe FlowdockService do
  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    context 'when service is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:token) }
    end

    context 'when service is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:token) }
    end
  end

  describe "Execute" do
    let(:user)    { create(:user) }
    let(:project) { create(:project, :repository) }

    before do
      @flowdock_service = described_class.new
      allow(@flowdock_service).to receive_messages(
        project_id: project.id,
        project: project,
        service_hook: true,
        token: 'verySecret'
      )
      @sample_data = Gitlab::DataBuilder::Push.build_sample(project, user)
      @api_url = 'https://api.flowdock.com/v1/messages'
      WebMock.stub_request(:post, @api_url)
    end

    it "calls FlowDock API" do
      @flowdock_service.execute(@sample_data)
      @sample_data[:commits].each do |commit|
        # One request to Flowdock per new commit
        next if commit[:id] == @sample_data[:before]

        expect(WebMock).to have_requested(:post, @api_url).with(
          body: /#{commit[:id]}.*#{project.path}/
        ).once
      end
    end
  end
end
