# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Ml::CandidatesController, feature_category: :mlops do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.first_owner }
  let_it_be(:experiment) { create(:ml_experiments, project: project, user: user) }
  let_it_be(:candidate) do
    create(:ml_candidates, experiment: experiment, user: user, project: project).tap do |c|
      c.update!(ci_build: create(:ci_build))
    end
  end

  let(:ff_value) { true }
  let(:candidate_iid) { candidate.iid }
  let(:read_model_experiments) { true }
  let(:write_model_experiments) { true }

  before do
    allow(Ability).to receive(:allowed?).and_call_original
    allow(Ability).to receive(:allowed?)
                        .with(user, :read_model_experiments, project)
                        .and_return(read_model_experiments)
    allow(Ability).to receive(:allowed?)
                        .with(user, :write_model_experiments, project)
                        .and_return(write_model_experiments)
    sign_in(user)
  end

  shared_examples 'renders 404' do
    it 'renders 404' do
      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples '404 if candidate does not exist' do
    context 'when experiment does not exist' do
      let(:candidate_iid) { non_existing_record_id }

      it_behaves_like 'renders 404'
    end
  end

  shared_examples 'requires read_model_experiments' do
    context 'when user does not have access' do
      let(:read_model_experiments) { false }

      it_behaves_like 'renders 404'
    end
  end

  describe 'GET show' do
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

    it_behaves_like '404 if candidate does not exist'
    it_behaves_like 'requires read_model_experiments'
  end

  describe 'GET promote' do
    before do
      promote_candidate
    end

    it 'renders the template' do
      expect(response).to render_template('projects/ml/candidates/promote')
    end

    it_behaves_like '404 if candidate does not exist'
    describe 'requires write_model_experiments' do
      let(:write_model_experiments) { false }

      it 'is 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'DELETE #destroy' do
    let_it_be(:candidate_for_deletion) do
      create(:ml_candidates, project: project, experiment: experiment, user: user)
    end

    let(:candidate_iid) { candidate_for_deletion.iid }

    before do
      destroy_candidate
    end

    it 'deletes the experiment', :aggregate_failures do
      expect(response).to have_gitlab_http_status(:found)
      expect(flash[:notice]).to eq('Run removed')
      expect(response).to redirect_to("/#{project.full_path}/-/ml/experiments/#{experiment.iid}")
      expect { Ml::Candidate.find(id: candidate_for_deletion.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it_behaves_like '404 if candidate does not exist'

    describe 'requires write_model_experiments' do
      let(:write_model_experiments) { false }

      it 'is 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  private

  def show_candidate
    get project_ml_candidate_path(project, iid: candidate_iid)
  end

  def promote_candidate
    get promote_project_ml_candidate_path(project, iid: candidate_iid)
  end

  def destroy_candidate
    delete project_ml_candidate_path(project, candidate_iid)
  end
end
