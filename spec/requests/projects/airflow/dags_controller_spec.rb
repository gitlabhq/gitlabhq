# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Airflow::DagsController, feature_category: :dataops do
  let_it_be(:non_member) { create(:user) }
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group).tap { |p| p.add_developer(user) } }
  let_it_be(:project) { create(:project, group: group).tap { |p| p.add_developer(user) } }

  let(:current_user) { user }
  let(:feature_flag) { true }

  let_it_be(:dags) do
    create_list(:airflow_dags, 5, project: project)
  end

  let(:params) { { namespace_id: project.namespace.to_param, project_id: project } }
  let(:extra_params) { {} }

  before do
    sign_in(current_user) if current_user
    stub_feature_flags(airflow_dags: false)
    stub_feature_flags(airflow_dags: project) if feature_flag
    list_dags
  end

  shared_examples 'returns a 404 if feature flag disabled' do
    context 'when :airflow_dags disabled' do
      let(:feature_flag) { false }

      it 'is 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET index' do
    it 'renders the template' do
      expect(response).to render_template('projects/airflow/dags/index')
    end

    describe 'pagination' do
      before do
        stub_const("Projects::Airflow::DagsController::MAX_DAGS_PER_PAGE", 2)
        dags

        list_dags
      end

      context 'when out of bounds' do
        let(:params) { extra_params.merge(page: 10000) }

        it 'redirects to last page' do
          last_page = (dags.size + 1) / 2
          expect(response).to redirect_to(project_airflow_dags_path(project, page: last_page))
        end
      end

      context 'when bad page' do
        let(:params) { extra_params.merge(page: 's') }

        it 'uses first page' do
          expect(assigns(:pagination)).to include(
            page: 1,
            is_last_page: false,
            per_page: 2,
            total_items: dags.size)
        end
      end
    end

    it 'does not perform N+1 sql queries' do
      control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) { list_dags }

      create_list(:airflow_dags, 1, project: project)

      expect { list_dags }.not_to exceed_all_query_limit(control_count)
    end

    context 'when user is not logged in' do
      let(:current_user) { nil }

      it 'redirects to login' do
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is not a member' do
      let(:current_user) { non_member }

      it 'returns a 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it_behaves_like 'returns a 404 if feature flag disabled'
  end

  private

  def list_dags
    get project_airflow_dags_path(project), params: params
  end
end
