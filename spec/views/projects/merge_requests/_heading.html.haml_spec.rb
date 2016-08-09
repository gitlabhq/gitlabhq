require 'spec_helper'

describe 'projects/merge_requests/widget/_heading' do
  include Devise::TestHelpers

  context 'when released to an environment' do
    let(:project)       { merge_request.target_project }
    let(:merge_request) { create(:merge_request, :merged) }
    let(:environment)   { create(:environment, project: project) }
    let!(:deployment)   do
      create(:deployment, environment: environment, sha: project.commit('master').id)
    end

    before do
      assign(:merge_request, merge_request)
      assign(:project, project)

      render
    end

    it 'displays that the environment is deployed' do
      expect(rendered).to match("Deployed to")
      expect(rendered).to match("#{environment.name}")
    end
  end
end
