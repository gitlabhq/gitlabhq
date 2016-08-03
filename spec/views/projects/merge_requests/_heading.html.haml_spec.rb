require 'spec_helper'

describe 'projects/merge_requests/widget/_heading' do
  include Devise::TestHelpers

  context 'when released to an environment' do
    let(:project)       { merge_request.target_project }
    let(:merge_request) { create(:merge_request, :merged) }
    let(:environment)   { create(:environment, project: project) }
    let!(:deployment)   { create(:deployment, environment: environment,
                                    sha: 'a5391128b0ef5d21df5dd23d98557f4ef12fae20') }

    before do
      assign(:merge_request, merge_request)

      render
    end

    it 'displays that the environment is deployed' do
      expect(rendered).to match('Released to')
    end
  end
end
