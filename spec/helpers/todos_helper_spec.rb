# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TodosHelper do
  let_it_be(:user) { create(:user) }
  let_it_be(:author) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, title: 'Issue 1', project: project) }
  let_it_be(:design) { create(:design, issue: issue) }
  let_it_be(:note) do
    create(:note, project: issue.project, note: 'I am note, hear me roar')
  end

  let_it_be(:group) { create(:group, :public, name: 'Group 1') }

  let_it_be(:design_todo) do
    create(
      :todo,
      :mentioned,
      user: user,
      project: project,
      target: design,
      author: author,
      note: note
    )
  end

  let_it_be(:alert_todo) do
    alert = create(:alert_management_alert, iid: 1001)
    create(:todo, target: alert)
  end

  let_it_be(:task_todo) do
    task = create(:work_item, :task, project: project)
    create(:todo, target: task, target_type: task.class.name, project: project)
  end

  let_it_be(:issue_todo) do
    create(:todo, target: issue)
  end

  let_it_be(:group_todo) do
    create(:todo, target: group, group: group, project: nil, user: user)
  end

  let_it_be(:project_access_request_todo) do
    create(:todo, target: project, action: Todo::MEMBER_ACCESS_REQUESTED)
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

    context 'when given a task' do
      let(:todo) { task_todo }

      it 'responds with an appropriate path using iid' do
        path = helper.todo_target_path(todo)

        expect(path).to eq("/#{todo.project.full_path}/-/work_items/#{todo.target.iid}")
      end
    end

    context 'when given an issue with a note anchor' do
      let(:todo) { create(:todo, project: issue.project, target: issue, note: note) }

      it 'responds with an appropriate path' do
        path = helper.todo_target_path(todo)

        expect(path).to eq("/#{issue.project.full_path}/-/issues/#{issue.iid}##{dom_id(note)}")
      end
    end

    context 'when a user requests access to group' do
      let_it_be(:group_access_request_todo) do
        create(
          :todo,
          target_id: group.id,
          target_type: group.class.polymorphic_name,
          group: group,
          action: Todo::MEMBER_ACCESS_REQUESTED
        )
      end

      it 'responds with access requests tab' do
        path = helper.todo_target_path(group_access_request_todo)

        access_request_path = Gitlab::Routing.url_helpers.group_group_members_path(group, tab: 'access_requests')

        expect(path).to eq(access_request_path)
      end
    end

    context 'when a user requests access to project' do
      it 'responds with access requests tab' do
        path = helper.todo_target_path(project_access_request_todo)

        access_request_path = Gitlab::Routing.url_helpers.project_project_members_path(project, tab: 'access_requests')

        expect(path).to eq(access_request_path)
      end
    end

    context 'when a SSH expired' do
      subject { helper.todo_target_path(todo) }

      let(:key) { create(:key, user: user) }
      let(:todo) { build(:todo, target: key, project: nil, user: user) }

      it { is_expected.to eq user_settings_ssh_key_path(key) }
    end
  end

  describe '#todo_types_options' do
    it 'includes a match for a design todo' do
      options = helper.todo_types_options
      design_option = options.find { |o| o[:id] == design_todo.target_type }

      expect(design_option).to include(text: 'Design')
    end
  end

  describe '#no_todos_messages' do
    context 'when getting todos messages' do
      it 'return these sentences' do
        expected_sentences = [
          s_('Todos|Good job! Looks like you don\'t have anything left on your To-Do List'),
          s_('Todos|Isn\'t an empty To-Do List beautiful?'),
          s_('Todos|Give yourself a pat on the back!'),
          s_('Todos|Nothing left to do. High five!'),
          s_('Todos|Henceforth, you shall be known as "To-Do Destroyer"')
        ]
        expect(helper.no_todos_messages).to eq(expected_sentences)
      end
    end
  end

  describe '#todos_filter_params' do
    using RSpec::Parameterized::TableSyntax

    where(:state, :result) do
      'done'    | 'done'
      'pending' | 'pending'
      ''        | nil
    end

    with_them do
      before do
        allow(helper).to receive(:params).and_return({ state: state })
      end

      it { expect(helper.todos_filter_params[:state]).to eq(result) }
    end
  end

  describe '#todo_parent_path' do
    context 'when todo resource parent is a group' do
      subject(:result) { helper.todo_parent_path(group_todo) }

      it { expect(result).to eq(group_todo.group.name) }
    end

    context 'when todo resource parent is not a group' do
      context 'when todo belongs to no project either' do
        let(:todo) { build(:todo, group: nil, project: nil, user: user) }

        subject(:result) { helper.todo_parent_path(todo) }

        it { expect(result).to eq(nil) }
      end

      it 'returns project title with namespace' do
        result = helper.todo_parent_path(project_access_request_todo)

        expect(result).to include(project_access_request_todo.project.name)
        expect(result).to include(project_access_request_todo.project.namespace.human_name)
      end
    end
  end

  describe '.todo_groups_requiring_saml_reauth', feature_category: :system_access do
    it 'returns an empty array' do
      expect(helper.todo_groups_requiring_saml_reauth([])).to match_array([])
    end
  end
end
