# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Ml::CandidatesController, feature_category: :mlops do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.first_owner }
  let_it_be(:experiment) { create(:ml_experiments, project: project, user: user) }
  let_it_be(:candidate) { create(:ml_candidates, experiment: experiment, user: user) }

  let(:ff_value) { true }
  let(:candidate_iid) { candidate.iid }

  before do
    stub_feature_flags(ml_experiment_tracking: false)
    stub_feature_flags(ml_experiment_tracking: project) if ff_value

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

  describe 'GET show' do
    let(:params) { basic_params.merge(id: experiment.iid) }

    before do
      show_candidate
    end

    it 'renders the template' do
      expect(response).to render_template('projects/ml/candidates/show')
    end

    it 'does not perform N+1 sql queries' do
      control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) { show_candidate }

      create_list(:ml_candidate_params, 3, candidate: candidate)
      create_list(:ml_candidate_metrics, 3, candidate: candidate)

      expect { show_candidate }.not_to exceed_all_query_limit(control_count)
    end

    context 'when candidate does not exist' do
      let(:candidate_iid) { non_existing_record_id.to_s }

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it_behaves_like '404 if feature flag disabled'
  end

  private

  def show_candidate
    get project_ml_candidate_path(project, candidate_iid)
  end
end
