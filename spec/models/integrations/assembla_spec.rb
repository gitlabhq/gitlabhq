# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Assembla do
  include StubRequests

  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe "Execute" do
    let(:user)    { create(:user) }
    let(:project) { create(:project, :repository) }

    before do
      @assembla_service = described_class.new
      allow(@assembla_service).to receive_messages(
        project_id: project.id,
        project: project,
        service_hook: true,
        token: 'verySecret',
        subdomain: 'project_name'
      )
      @sample_data = Gitlab::DataBuilder::Push.build_sample(project, user)
      @api_url = 'https://atlas.assembla.com/spaces/project_name/github_tool?secret_key=verySecret'
      stub_full_request(@api_url, method: :post)
    end

    it "calls Assembla API" do
      @assembla_service.execute(@sample_data)
      expect(WebMock).to have_requested(:post, stubbed_hostname(@api_url)).with(
        body: /#{@sample_data[:before]}.*#{@sample_data[:after]}.*#{project.path}/
      ).once
    end
  end
end
