# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Flowdock do
  describe 'Validations' do
    context 'when integration is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:token) }
    end

    context 'when integration is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:token) }
    end
  end

  describe "Execute" do
    let(:user)    { create(:user) }
    let(:project) { create(:project, :repository) }
    let(:sample_data) { Gitlab::DataBuilder::Push.build_sample(project, user) }
    let(:api_url) { 'https://api.flowdock.com/v1/messages' }

    subject(:flowdock_integration) { described_class.new }

    before do
      allow(flowdock_integration).to receive_messages(
        project_id: project.id,
        project: project,
        token: 'verySecret'
      )
      WebMock.stub_request(:post, api_url)
    end

    it "calls FlowDock API" do
      flowdock_integration.execute(sample_data)

      sample_data[:commits].each do |commit|
        # One request to Flowdock per new commit
        next if commit[:id] == sample_data[:before]

        expect(WebMock).to have_requested(:post, api_url).with(
          body: /#{commit[:id]}.*#{project.path}/
        ).once
      end
    end
  end
end
