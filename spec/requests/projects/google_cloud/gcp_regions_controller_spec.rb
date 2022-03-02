# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GoogleCloud::GcpRegionsController do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:repository) { project.repository }

  RSpec.shared_examples "should be not found" do
    it 'returns not found' do
      is_expected.to be(404)
    end
  end

  RSpec.shared_examples "should be forbidden" do
    it 'returns forbidden' do
      is_expected.to be(403)
    end
  end

  RSpec.shared_examples "public request should 404" do
    it_behaves_like "should be not found"
  end

  RSpec.shared_examples "unauthorized access should 404" do
    let(:user_guest) { create(:user) }

    before do
      project.add_guest(user_guest)
    end

    it_behaves_like "should be not found"
  end

  describe 'GET #index' do
    subject { get project_google_cloud_gcp_regions_path(project) }

    it_behaves_like "public request should 404"
    it_behaves_like "unauthorized access should 404"

    context 'when authorized members make requests' do
      let(:user_maintainer) { create(:user) }

      before do
        project.add_maintainer(user_maintainer)
        sign_in(user_maintainer)
      end

      it 'renders gcp_regions' do
        is_expected.to render_template('projects/google_cloud/gcp_regions/index')
      end

      context 'but gitlab instance is not configured for google oauth2' do
        before do
          unconfigured_google_oauth2 = Struct.new(:app_id, :app_secret)
                                             .new('', '')
          allow(Gitlab::Auth::OAuth::Provider).to receive(:config_for)
                                                    .with('google_oauth2')
                                                    .and_return(unconfigured_google_oauth2)
        end

        it_behaves_like "should be forbidden"
      end

      context 'but feature flag is disabled' do
        before do
          stub_feature_flags(incubation_5mp_google_cloud: false)
        end

        it_behaves_like "should be not found"
      end
    end
  end

  describe 'POST #index' do
    subject { post project_google_cloud_gcp_regions_path(project), params: { gcp_region: 'region1', environment: 'env1' } }

    it_behaves_like "public request should 404"
    it_behaves_like "unauthorized access should 404"

    context 'when authorized members make requests' do
      let(:user_maintainer) { create(:user) }

      before do
        project.add_maintainer(user_maintainer)
        sign_in(user_maintainer)
      end

      it 'redirects to google cloud index' do
        is_expected.to redirect_to(project_google_cloud_index_path(project))
      end
    end
  end
end
