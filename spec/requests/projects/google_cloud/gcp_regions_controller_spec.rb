# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GoogleCloud::GcpRegionsController, feature_category: :deployment_management do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:repository) { project.repository }

  let_it_be(:user_guest) { create(:user) }
  let_it_be(:user_maintainer) { create(:user) }

  RSpec.shared_examples "should track not_found event" do
    it "tracks event" do
      is_expected.to be(404)
      expect_snowplow_event(
        category: 'Projects::GoogleCloud::GcpRegionsController',
        action: 'error_invalid_user',
        label: nil,
        project: project,
        user: nil
      )
    end
  end

  RSpec.shared_examples "should track access_denied event" do
    it "tracks event" do
      is_expected.to be(404)
      expect_snowplow_event(
        category: 'Projects::GoogleCloud::GcpRegionsController',
        action: 'error_invalid_user',
        label: nil,
        project: project,
        user: nil
      )
    end
  end

  RSpec.shared_examples "should track gcp_error event" do |config|
    it "tracks event" do
      is_expected.to be(403)
      expect_snowplow_event(
        category: 'Projects::GoogleCloud::GcpRegionsController',
        action: 'error_google_oauth2_not_enabled',
        label: nil,
        project: project,
        user: user_maintainer
      )
    end
  end

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
    it_behaves_like "should track not_found event"
  end

  RSpec.shared_examples "unauthorized access should 404" do
    before do
      project.add_guest(user_guest)
    end

    it_behaves_like "should be not found"
    it_behaves_like "should track access_denied event"
  end

  describe 'GET #index', :snowplow do
    subject { get project_google_cloud_gcp_regions_path(project) }

    it_behaves_like "public request should 404"
    it_behaves_like "unauthorized access should 404"

    context 'when authorized members make requests' do
      before do
        project.add_maintainer(user_maintainer)
        sign_in(user_maintainer)
      end

      it 'renders gcp_regions' do
        is_expected.to render_template('projects/google_cloud/gcp_regions/index')
      end

      context 'but gitlab instance is not configured for google oauth2' do
        unconfigured_google_oauth2 = Struct.new(:app_id, :app_secret)
                                           .new('', '')

        before do
          allow(Gitlab::Auth::OAuth::Provider).to receive(:config_for)
                                                    .with('google_oauth2')
                                                    .and_return(unconfigured_google_oauth2)
        end

        it_behaves_like "should be forbidden"
        it_behaves_like "should track gcp_error event", unconfigured_google_oauth2
      end
    end
  end

  describe 'POST #index', :snowplow do
    subject { post project_google_cloud_gcp_regions_path(project), params: { gcp_region: 'region1', environment: 'env1' } }

    it_behaves_like "public request should 404"
    it_behaves_like "unauthorized access should 404"

    context 'when authorized members make requests' do
      before do
        project.add_maintainer(user_maintainer)
        sign_in(user_maintainer)
      end

      it 'redirects to google cloud configurations' do
        is_expected.to redirect_to(project_google_cloud_configuration_path(project))
      end
    end
  end
end
