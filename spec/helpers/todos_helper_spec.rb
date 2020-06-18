# frozen_string_literal: true

require 'spec_helper'

describe TodosHelper do
  let_it_be(:user) { create(:user) }
  let_it_be(:author) { create(:user) }
  let_it_be(:issue) { create(:issue, title: 'Issue 1') }
  let_it_be(:design) { create(:design, issue: issue) }
  let_it_be(:note) do
    create(:note,
           project: issue.project,
           note: 'I am note, hear me roar')
  end
  let_it_be(:design_todo) do
    create(:todo, :mentioned,
           user: user,
           project: issue.project,
           target: design,
           author: author,
           note: note)
  end
  let_it_be(:alert_todo) do
    alert = create(:alert_management_alert, iid: 1001)
    create(:todo, target: alert)
  end

  describe '#todos_count_format' do
    it 'shows fuzzy count for 100 or more items' do
      expect(helper.todos_count_format(100)).to eq '99+'
      expect(helper.todos_count_format(1000)).to eq '99+'
    end

    it 'shows exact count for 99 or fewer items' do
      expect(helper.todos_count_format(99)).to eq '99'
      expect(helper.todos_count_format(50)).to eq '50'
      expect(helper.todos_count_format(1)).to eq '1'
    end
  end

  describe '#todo_projects_options' do
    let(:projects) { create_list(:project, 3) }
    let(:user)     { create(:user) }

    it 'returns users authorised projects in json format' do
      projects.first.add_developer(user)
      projects.second.add_developer(user)

      allow(helper).to receive(:current_user).and_return(user)

      expected_results = [
        { 'id' => '', 'text' => 'Any Project' },
        { 'id' => projects.second.id, 'text' => projects.second.full_name },
        { 'id' => projects.first.id, 'text' => projects.first.full_name }
      ]

      expect(Gitlab::Json.parse(helper.todo_projects_options)).to match_array(expected_results)
    end
  end

  describe '#todo_target_link' do
    context 'when given a design' do
      let(:todo) { design_todo }

      it 'produces a good link' do
        path = helper.todo_target_path(todo)
        link = helper.todo_target_link(todo)
        expected = "<a href=\"#{path}\">design #{design.to_reference}</a>"

        expect(link).to eq(expected)
      end
    end
  end

  describe '#todo_target_title' do
    context 'when the target does not exist' do
      let(:todo) { double('Todo', target: nil) }

      it 'returns an empty string' do
        title = helper.todo_target_title(todo)
        expect(title).to eq("")
      end
    end

    context 'when given a design todo' do
      let(:todo) { design_todo }

      it 'returns an empty string' do
        title = helper.todo_target_title(todo)
        expect(title).to eq("")
      end
    end

    context 'when given a non-design todo' do
      let(:todo) do
        build_stubbed(:todo, :assigned,
        user: user,
        project: issue.project,
        target: issue,
        author: author)
      end

      it 'returns the title' do
        title = helper.todo_target_title(todo)
        expect(title).to eq("\"Issue 1\"")
      end
    end
  end

  describe '#todo_target_path' do
    context 'when given a design' do
      let(:todo) { design_todo }

      it 'responds with an appropriate path' do
        path = helper.todo_target_path(todo)
        issue_path = Gitlab::Routing.url_helpers
          .project_issue_path(issue.project, issue)

        expect(path).to eq("#{issue_path}/designs/#{design.filename}##{dom_id(design_todo.note)}")
      end
    end

    context 'when given an alert' do
      let(:todo) { alert_todo }

      it 'responds with an appropriate path' do
        path = helper.todo_target_path(todo)

        expect(path).to eq(
          "/#{todo.project.full_path}/-/alert_management/#{todo.target.iid}/details"
        )
      end
    end
  end

  describe '#todo_target_type_name' do
    context 'when given a design todo' do
      let(:todo) { design_todo }

      it 'responds with an appropriate target type name' do
        name = helper.todo_target_type_name(todo)

        expect(name).to eq('design')
      end
    end

    context 'when given an alert todo' do
      let(:todo) { alert_todo }

      it 'responds with an appropriate target type name' do
        name = helper.todo_target_type_name(todo)

        expect(name).to eq('alert')
      end
    end
  end

  describe '#todo_types_options' do
    it 'includes a match for a design todo' do
      options = helper.todo_types_options
      design_option = options.find { |o| o[:id] == design_todo.target_type }

      expect(design_option).to include(text: 'Design')
    end
  end
end
