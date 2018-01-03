require 'spec_helper'

describe 'Todos (JavaScript fixtures)' do
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin) }
  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project_empty_repo, namespace: namespace, path: 'todos-project') }
  let(:issue_1) { create(:issue, title: 'issue_1', project: project) }
  let!(:todo_1) { create(:todo, user: admin, project: project, target: issue_1, created_at: 5.hours.ago) }
  let(:issue_2) { create(:issue, title: 'issue_2', project: project) }
  let!(:todo_2) { create(:todo, :done, user: admin, project: project, target: issue_2, created_at: 50.hours.ago) }

  before(:all) do
    clean_frontend_fixtures('todos/')
  end

  after do
    remove_repository(project)
  end

  describe Dashboard::TodosController, '(JavaScript fixtures)', type: :controller do
    render_views

    before do
      sign_in(admin)
    end

    it 'todos/todos.html.raw' do |example|
      get :index

      expect(response).to be_success
      store_frontend_fixture(response, example.description)
    end
  end

  describe Projects::TodosController, '(JavaScript fixtures)', type: :controller do
    render_views

    before do
      sign_in(admin)
    end

    it 'todos/todos.json' do |example|
      post :create,
        namespace_id: namespace,
        project_id: project,
        issuable_type: 'issue',
        issuable_id: issue_2.id,
        format: 'json'

      expect(response).to be_success
      store_frontend_fixture(response, example.description)
    end
  end
end
