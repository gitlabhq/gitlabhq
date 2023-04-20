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
  let(:experiment_iid) { experiment.iid }

  before do
    stub_feature_flags(ml_experiment_tracking: false)
    stub_feature_flags(ml_experiment_tracking: project_with_feature) if ff_value

    sign_in(user)
  end

  shared_examples 'renders 404' do
    it 'renders 404' do
      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples '404 if experiment does not exist' do
    context 'when experiment does not exist' do
      let(:experiment_iid) { non_existing_record_id }

      it_behaves_like 'renders 404'
    end
  end

  shared_examples '404 if feature flag disabled' do
    context 'when :ml_experiment_tracking disabled' do
      let(:ff_value) { false }

      it_behaves_like 'renders 404'
    end
  end

  describe 'GET index' do
    describe 'renderering' do
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
    end

    describe 'pagination' do
      let_it_be(:experiments) do
        create_list(:ml_experiments, 3, project: project_with_feature)
      end

      let(:params) { basic_params.merge(id: experiment.iid) }

      before do
        stub_const("Projects::Ml::ExperimentsController::MAX_EXPERIMENTS_PER_PAGE", 2)

        list_experiments
      end

      it 'fetches only MAX_CANDIDATES_PER_PAGE candidates' do
        expect(assigns(:experiments).size).to eq(2)
      end

      it 'paginates', :aggregate_failures do
        page = assigns(:experiments)

        expect(page.first).to eq(experiments.last)
        expect(page.last).to eq(experiments[1])

        new_params = params.merge(cursor: assigns(:page_info)[:end_cursor])

        list_experiments(new_params)

        new_page = assigns(:experiments)

        expect(new_page.first).to eq(experiments.first)
      end
    end

    context 'when :ml_experiment_tracking is disabled for the project' do
      let(:project) { project_without_feature }

      before do
        list_experiments
      end

      it 'responds with a 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it_behaves_like '404 if feature flag disabled' do
      before do
        list_experiments
      end
    end
  end

  describe 'GET show' do
    describe 'html' do
      it 'renders the template' do
        show_experiment

        expect(response).to render_template('projects/ml/experiments/show')
      end

      describe 'pagination' do
        let_it_be(:candidates) do
          create_list(:ml_candidates, 5, experiment: experiment).tap do |c|
            c.first.metrics.create!(name: 'metric1', value: 0.3)
            c[1].metrics.create!(name: 'metric1', value: 0.2)
            c.last.metrics.create!(name: 'metric1', value: 0.6)
          end
        end

        let(:params) { basic_params.merge(id: experiment.iid) }

        before do
          stub_const("Projects::Ml::ExperimentsController::MAX_CANDIDATES_PER_PAGE", 2)

          show_experiment
        end

        it 'fetches only MAX_CANDIDATES_PER_PAGE candidates' do
          expect(assigns(:candidates).size).to eq(2)
        end

        it 'paginates' do
          received = assigns(:page_info)

          expect(received).to include({
            has_next_page: true,
            has_previous_page: false,
            start_cursor: nil
          })
        end

        context 'when order by metric' do
          let(:params) do
            {
              order_by: "metric1",
              order_by_type: "metric",
              sort: "desc"
            }
          end

          it 'paginates', :aggregate_failures do
            page = assigns(:candidates)

            expect(page.first).to eq(candidates.last)
            expect(page.last).to eq(candidates.first)

            new_params = params.merge(cursor: assigns(:page_info)[:end_cursor])

            show_experiment(new_params: new_params)

            new_page = assigns(:candidates)

            expect(new_page.first).to eq(candidates[1])
          end
        end
      end

      describe 'search' do
        let(:params) do
          basic_params.merge(
            name: 'some_name',
            orderBy: 'name',
            orderByType: 'metric',
            sort: 'asc',
            invalid: 'invalid'
          )
        end

        it 'formats and filters the parameters' do
          expect(Projects::Ml::CandidateFinder).to receive(:new).and_call_original do |exp, params|
            expect(params.to_h).to include({
              name: 'some_name',
              order_by: 'name',
              order_by_type: 'metric',
              sort: 'asc'
            })
          end

          show_experiment
        end
      end

      it 'does not perform N+1 sql queries' do
        control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) { show_experiment }

        create_list(:ml_candidates, 2, :with_metrics_and_params, experiment: experiment)

        expect { show_experiment }.not_to exceed_all_query_limit(control_count)
      end

      describe '404' do
        before do
          show_experiment
        end

        it_behaves_like '404 if experiment does not exist'
        it_behaves_like '404 if feature flag disabled'
      end
    end

    describe 'csv' do
      it 'responds with :ok', :aggregate_failures do
        show_experiment_csv

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers['Content-Type']).to eq('text/csv; charset=utf-8')
      end

      it 'calls the presenter' do
        allow(::Ml::CandidatesCsvPresenter).to receive(:new).and_call_original

        show_experiment_csv
      end

      it 'does not perform N+1 sql queries' do
        control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) { show_experiment_csv }

        create_list(:ml_candidates, 2, :with_metrics_and_params, experiment: experiment)

        expect { show_experiment_csv }.not_to exceed_all_query_limit(control_count)
      end

      describe '404' do
        before do
          show_experiment_csv
        end

        it_behaves_like '404 if experiment does not exist'
        it_behaves_like '404 if feature flag disabled'
      end
    end
  end

  describe 'DELETE #destroy' do
    let_it_be(:experiment_for_deletion) do
      create(:ml_experiments, project: project_with_feature, user: user).tap do |e|
        create(:ml_candidates, experiment: e, user: user)
      end
    end

    let_it_be(:candidate_for_deletion) { experiment_for_deletion.candidates.first }

    let(:params) { basic_params.merge(id: experiment.iid) }

    before do
      destroy_experiment
    end

    it 'deletes the experiment' do
      expect { experiment.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it_behaves_like '404 if experiment does not exist'
    it_behaves_like '404 if feature flag disabled'
  end

  private

  def show_experiment(new_params: nil, format: :html)
    get project_ml_experiment_path(project, experiment_iid, format: format), params: new_params || params
  end

  def show_experiment_csv
    show_experiment(format: :csv)
  end

  def list_experiments(new_params = nil)
    get project_ml_experiments_path(project), params: new_params || params
  end

  def destroy_experiment
    delete project_ml_experiment_path(project, experiment_iid), params: params
  end
end
