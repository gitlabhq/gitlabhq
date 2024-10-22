# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Ml::ModelsController, feature_category: :mlops do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.first_owner }
  let_it_be(:model1) { create(:ml_models, :with_versions, project: project) }

  let(:read_model_registry) { true }
  let(:write_model_registry) { true }

  let(:params) { {} }

  before do
    allow(Ability).to receive(:allowed?).and_call_original
    allow(Ability).to receive(:allowed?)
                        .with(user, :read_model_registry, project)
                        .and_return(read_model_registry)
    allow(Ability).to receive(:allowed?)
                        .with(user, :write_model_registry, project)
                        .and_return(write_model_registry)

    sign_in(user)
  end

  describe 'GET index' do
    subject(:index_request) do
      list_models
      response
    end

    it 'renders the template' do
      expect(index_request).to render_template('projects/ml/models/index')
    end

    context 'when user does not have access' do
      let(:read_model_registry) { false }

      it 'renders 404' do
        is_expected.to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'show' do
    let(:model_id) { model1.id }
    let(:request_project) { model1.project }

    subject(:show_request) do
      show_model
      response
    end

    before do
      show_request
    end

    it 'renders the template' do
      is_expected.to render_template('projects/ml/models/show')
    end

    it 'fetches the correct model' do
      show_request

      expect(assigns(:model)).to eq(model1)
    end

    context 'when model id does not exist' do
      let(:model_id) { non_existing_record_id }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when model project does not match project id' do
      let_it_be(:request_project) { create(:project) }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when user does not have access' do
      let(:read_model_registry) { false }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end
  end

  describe 'GET new' do
    subject(:create_model_request) do
      new_model
      response
    end

    before do
      create_model_request
    end

    it 'renders the template' do
      is_expected.to render_template('projects/ml/models/new')
    end

    context 'when user does not have access' do
      let(:write_model_registry) { false }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end
  end

  describe 'edit' do
    let(:model_id) { model1.id }
    let(:request_project) { model1.project }

    subject(:edit_request) do
      edit_model
      response
    end

    before do
      edit_request
    end

    it 'renders the template' do
      is_expected.to render_template('projects/ml/models/edit')
    end

    it 'fetches the correct model' do
      edit_request

      expect(assigns(:model)).to eq(model1)
    end

    context 'when model id does not exist' do
      let(:model_id) { non_existing_record_id }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when model project does not match project id' do
      let(:request_project) { create(:project) }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when user does not have access' do
      let(:write_model_registry) { false }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end
  end

  describe 'destroy' do
    let(:model_for_deletion) do
      create(:ml_models, project: project)
    end

    let(:model_id) { model_for_deletion.id }

    subject(:delete_request) do
      delete_model
      response
    end

    it 'deletes the model', :aggregate_failures do
      is_expected.to have_gitlab_http_status(:found)

      expect(flash[:notice]).to eq('Model removed')
      expect(response).to redirect_to("/#{project.full_path}/-/ml/models")
      expect { Ml::Model.find(id: model_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context 'when model does not exist' do
      let(:model_id) { non_existing_record_id }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    describe 'when user does not have write_model_registry rights' do
      let(:write_model_registry) { false }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end
  end

  private

  def list_models(new_params = nil)
    get project_ml_models_path(project), params: new_params || params
  end

  def show_model
    get project_ml_model_path(request_project, model_id)
  end

  def delete_model
    delete project_ml_model_path(project, model_id)
  end

  def new_model
    get new_project_ml_model_path(project)
  end

  def edit_model
    get edit_project_ml_model_path(request_project, model_id)
  end
end
