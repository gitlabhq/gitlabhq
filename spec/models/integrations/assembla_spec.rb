# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Assembla do
  include StubRequests

  describe "Execute" do
    let(:user)    { create(:user) }
    let(:project) { create(:project, :repository) }

    before do
      @assembla_integration = described_class.new
      allow(@assembla_integration).to receive_messages(
        project_id: project.id,
        project: project,
        token: 'verySecret',
        subdomain: 'project_name'
      )
      @sample_data = Gitlab::DataBuilder::Push.build_sample(project, user)
      @api_url = 'https://atlas.assembla.com/spaces/project_name/github_tool?secret_key=verySecret'
      stub_full_request(@api_url, method: :post)
    end

    it "calls Assembla API" do
      @assembla_integration.execute(@sample_data)
      expect(WebMock).to have_requested(:post, stubbed_hostname(@api_url)).with(
        body: /#{@sample_data[:before]}.*#{@sample_data[:after]}.*#{project.path}/
      ).once
    end
  end
end
