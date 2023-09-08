# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Metrics::Dashboard::Annotations, feature_category: :metrics do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private, :repository, namespace: user.namespace) }
  let_it_be(:environment) { create(:environment, project: project) }

  let(:dashboard) { 'config/prometheus/common_metrics.yml' }
  let(:starting_at) { Time.now.iso8601 }
  let(:ending_at) { 1.hour.from_now.iso8601 }
  let(:params) { { environment: environment, starting_at: starting_at, ending_at: ending_at, dashboard_path: dashboard, description: 'desc' } }

  shared_examples 'POST /:source_type/:id/metrics_dashboard/annotations' do |source_type|
    let(:url) { "/#{source_type.pluralize}/#{source.id}/metrics_dashboard/annotations" }

    before do
      project.add_developer(user)
    end

    context "with :source_type == #{source_type.pluralize}" do
      context 'without correct permissions' do
        let_it_be(:guest) { create(:user) }

        before do
          project.add_guest(guest)
        end

        it 'returns error message' do
          post api(url, guest), params: params

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when metrics dashboard feature is unavailable' do
        before do
          stub_feature_flags(remove_monitor_metrics: true)
        end

        it 'returns 404 not found' do
          post api(url, user), params: params

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'environment' do
    it_behaves_like 'POST /:source_type/:id/metrics_dashboard/annotations', 'environment' do
      let(:source) { environment }
    end
  end

  describe 'group cluster' do
    it_behaves_like 'POST /:source_type/:id/metrics_dashboard/annotations', 'cluster' do
      let_it_be(:group) { create(:group) }
      let_it_be(:cluster) { create(:cluster_for_group, groups: [group]) }

      before do
        group.add_developer(user)
      end

      let(:source) { cluster }
    end
  end

  describe 'project cluster' do
    it_behaves_like 'POST /:source_type/:id/metrics_dashboard/annotations', 'cluster' do
      let_it_be(:cluster) { create(:cluster, projects: [project]) }

      let(:source) { cluster }
    end
  end
end
