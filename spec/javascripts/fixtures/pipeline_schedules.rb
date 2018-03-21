require 'spec_helper'

describe Projects::PipelineSchedulesController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin) }
  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project, :public, :repository) }
  let!(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project, owner: admin) }
  let!(:pipeline_schedule_populated) { create(:ci_pipeline_schedule, project: project, owner: admin) }
  let!(:pipeline_schedule_variable1) { create(:ci_pipeline_schedule_variable, key: 'foo', value: 'foovalue', pipeline_schedule: pipeline_schedule_populated) }
  let!(:pipeline_schedule_variable2) { create(:ci_pipeline_schedule_variable, key: 'bar', value: 'barvalue', pipeline_schedule: pipeline_schedule_populated) }

  render_views

  before(:all) do
    clean_frontend_fixtures('pipeline_schedules/')
  end

  before do
    sign_in(admin)
  end

  it 'pipeline_schedules/edit.html.raw' do |example|
    get :edit,
      namespace_id: project.namespace.to_param,
      project_id: project,
      id: pipeline_schedule.id

    expect(response).to be_success
    store_frontend_fixture(response, example.description)
  end

  it 'pipeline_schedules/edit_with_variables.html.raw' do |example|
    get :edit,
      namespace_id: project.namespace.to_param,
      project_id: project,
      id: pipeline_schedule_populated.id

    expect(response).to be_success
    store_frontend_fixture(response, example.description)
  end
end
