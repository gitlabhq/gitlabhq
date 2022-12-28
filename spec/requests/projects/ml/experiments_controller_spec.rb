# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Ml::ExperimentsController, feature_category: :mlops do
  let_it_be(:project_with_feature) { create(:project, :repository) }
  let_it_be(:user) { project_with_feature.first_owner }
  let_it_be(:project_without_feature) do
    create(:project, :repository).tap { |p| p.add_developer(user) }
  end

  let_it_be(:experiment) do
    create(:ml_experiments, project: project_with_feature, user: user).tap do |e|
      create(:ml_candidates, experiment: e, user: user)
    end
  end

  let(:params) { basic_params }
  let(:ff_value) { true }
  let(:project) { project_with_feature }
  let(:basic_params) { { namespace_id: project.namespace.to_param, project_id: project } }

  before do
    stub_feature_flags(ml_experiment_tracking: false)
    stub_feature_flags(ml_experiment_tracking: project_with_feature) if ff_value

    sign_in(user)
  end

  shared_examples '404 if feature flag disabled' do
    context 'when :ml_experiment_tracking disabled' do
      let(:ff_value) { false }

      it 'is 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET index' do
    before do
      list_experiments
    end

    it 'renders the template' do
      expect(response).to render_template('projects/ml/experiments/index')
    end

    it 'does not perform N+1 sql queries' do
      control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) { list_experiments }

      create_list(:ml_experiments, 2, project: project, user: user)

      expect { list_experiments }.not_to exceed_all_query_limit(control_count)
    end

    context 'when :ml_experiment_tracking is disabled for the project' do
      let(:project) { project_without_feature }

      it 'responds with a 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it_behaves_like '404 if feature flag disabled'
  end

  describe 'GET show' do
    let(:params) { basic_params.merge(id: experiment.iid) }

    before do
      show_experiment
    end

    it 'renders the template' do
      expect(response).to render_template('projects/ml/experiments/show')
    end

    it 'does not perform N+1 sql queries' do
      control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) { show_experiment }

      create_list(:ml_candidates, 2, :with_metrics_and_params, experiment: experiment)

      expect { show_experiment }.not_to exceed_all_query_limit(control_count)
    end

    it_behaves_like '404 if feature flag disabled'
  end

  private

  def show_experiment
    get project_ml_experiment_path(project, experiment.iid), params: params
  end

  def list_experiments
    get project_ml_experiments_path(project), params: params
  end
end
