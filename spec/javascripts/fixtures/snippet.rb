require 'spec_helper'

describe SnippetsController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin) }
  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project, :repository, namespace: namespace, path: 'branches-project') }
  let(:snippet) { create(:personal_snippet, title: 'snippet.md', content: '# snippet', file_name: 'snippet.md', author: admin) }
  let!(:snippet_note) { create(:discussion_note_on_snippet, noteable: snippet, project: project, author: admin) }

  render_views

  before(:all) do
    clean_frontend_fixtures('snippets/')
  end

  before do
    sign_in(admin)
  end

  after do
    remove_repository(project)
  end

  it 'snippets/show.html.raw' do |example|
    get(:show, id: snippet.to_param)

    expect(response).to be_success
    store_frontend_fixture(response, example.description)
  end
end
