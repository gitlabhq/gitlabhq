require "spec_helper"

describe TodosHelper do
  include GitlabRoutingHelper

  describe '#todo_target_path' do
    let(:project)       { create(:project) }
    let(:merge_request) { create(:merge_request, target_project: project, source_project: project) }
    let(:issue)         { create(:issue, project: project) }
    let(:note)          { create(:note_on_issue, noteable: issue, project: project) }

    let(:mr_todo)           { build(:todo, project: project, target: merge_request) }
    let(:issue_todo)        { build(:todo, project: project, target: issue) }
    let(:note_todo)         { build(:todo, project: project, target: issue, note: note) }
    let(:build_failed_todo) { build(:todo, :build_failed, project: project, target: merge_request) }

    it 'returns correct path to the todo MR' do
      expect(todo_target_path(mr_todo)).
        to eq("/#{project.full_path}/merge_requests/#{merge_request.iid}")
    end

    it 'returns correct path to the todo issue' do
      expect(todo_target_path(issue_todo)).
        to eq("/#{project.full_path}/issues/#{issue.iid}")
    end

    it 'returns correct path to the todo note' do
      expect(todo_target_path(note_todo)).
        to eq("/#{project.full_path}/issues/#{issue.iid}#note_#{note.id}")
    end

    it 'returns correct path to build_todo MR when pipeline failed' do
      expect(todo_target_path(build_failed_todo)).
        to eq("/#{project.full_path}/merge_requests/#{merge_request.iid}/pipelines")
    end
  end

  describe '#todo_projects_options' do
    let(:projects) { create_list(:empty_project, 3) }
    let(:user)     { create(:user) }

    it 'returns users authorised projects in json format' do
      projects.first.add_developer(user)
      projects.second.add_developer(user)

      allow(helper).to receive(:current_user).and_return(user)

      expected_results = [
        { 'id' => '', 'text' => 'Any Project' },
        { 'id' => projects.second.id, 'text' => projects.second.name_with_namespace },
        { 'id' => projects.first.id, 'text' => projects.first.name_with_namespace }
      ]

      expect(JSON.parse(helper.todo_projects_options)).to match_array(expected_results)
    end
  end
end
