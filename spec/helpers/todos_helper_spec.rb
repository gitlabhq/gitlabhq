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

  describe '#todo_target_name' do
    context 'when given a design' do
      let(:todo) { design_todo }

      it 'references the filename of the design' do
        name = helper.todo_target_name(todo)

        expect(name).to eq(design.to_reference.to_s)
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
        build_stubbed(
          :todo,
          :assigned,
          user: user,
          project: issue.project,
          target: issue,
          author: author
        )
      end

      it 'returns the title' do
        title = helper.todo_target_title(todo)
        expect(title).to eq("Issue 1")
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
  end

  describe '#todo_target_aria_label' do
    subject { helper.todo_target_aria_label(todo) }

    context 'when given a design todo' do
      let(:todo) { design_todo }

      it { is_expected.to eq("Design ##{todo.target.iid}[#{todo.target.title}]") }
    end

    context 'when given an alert todo' do
      let(:todo) { alert_todo }

      it { is_expected.to eq("Alert ^alert##{todo.target.iid}") }
    end

    context 'when given a task todo' do
      let(:todo) { task_todo }

      it { is_expected.to eq("Task ##{todo.target.iid}") }
    end

    context 'when given an issue todo' do
      let(:todo) { issue_todo }

      it { is_expected.to eq("Issue ##{todo.target.iid}") }
    end

    context 'when given a merge request todo' do
      let(:todo) do
        merge_request = create(:merge_request, source_project: project)
        create(:todo, target: merge_request)
      end

      it { is_expected.to eq("Merge Request !#{todo.target.iid}") }
    end
  end

  describe '#todo_types_options' do
    it 'includes a match for a design todo' do
      options = helper.todo_types_options
      design_option = options.find { |o| o[:id] == design_todo.target_type }

      expect(design_option).to include(text: 'Design')
    end
  end

  describe '#todo_target_state_pill' do
    subject { helper.todo_target_state_pill(todo) }

    shared_examples 'a rendered state pill' do |attr|
      it 'returns expected html' do
        aggregate_failures do
          expect(subject).to have_css(attr[:css])
          expect(subject).to have_content(attr[:state].capitalize)
        end
      end
    end

    shared_examples 'no state pill' do
      specify { expect(subject).to eq(nil) }
    end

    context 'merge request todo' do
      let(:todo) { create(:todo, target: create(:merge_request)) }

      it_behaves_like 'no state pill'

      context 'closed MR' do
        before do
          todo.target.update!(state: 'closed')
        end

        it_behaves_like 'a rendered state pill', css: '.badge-danger', state: 'closed'
      end

      context 'merged MR' do
        before do
          todo.target.update!(state: 'merged')
        end

        it_behaves_like 'a rendered state pill', css: '.badge-info', state: 'merged'
      end
    end

    context 'issue todo' do
      let(:todo) { create(:todo, target: issue) }

      it_behaves_like 'no state pill'

      context 'closed issue' do
        before do
          todo.target.update!(state: 'closed')
        end

        it_behaves_like 'a rendered state pill', css: '.badge-info', state: 'closed'
      end
    end

    context 'alert todo' do
      let(:todo) { alert_todo }

      it_behaves_like 'no state pill'

      context 'resolved alert' do
        before do
          todo.target.resolve!
        end

        it_behaves_like 'a rendered state pill', css: '.badge-info', state: 'resolved'
      end
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

  describe '#todo_author_display?' do
    using RSpec::Parameterized::TableSyntax

    subject { helper.todo_author_display?(alert_todo) }

    where(:action, :result) do
      Todo::BUILD_FAILED        | false
      Todo::UNMERGEABLE         | false
      Todo::ASSIGNED            | true
    end

    with_them do
      before do
        alert_todo.action = action
      end

      it { is_expected.to eq(result) }
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

  describe '#todo_action_name' do
    using RSpec::Parameterized::TableSyntax

    where(:action, :self_added?, :expected_action_name) do
      Todo::ASSIGNED            | false | s_('Todos|assigned you')
      Todo::ASSIGNED            | true  | s_('Todos|assigned')
      Todo::REVIEW_REQUESTED    | true  | s_('Todos|requested a review')
      Todo::MENTIONED           | true  | format(s_("Todos|mentioned %{who}"), who: s_('Todos|yourself'))
      Todo::MENTIONED           | false | format(s_("Todos|mentioned %{who}"), who: _('you'))
      Todo::DIRECTLY_ADDRESSED  | true  | format(s_("Todos|mentioned %{who}"), who: s_('Todos|yourself'))
      Todo::DIRECTLY_ADDRESSED  | false | format(s_("Todos|mentioned %{who}"), who: _('you'))
      Todo::BUILD_FAILED        | true  | s_('Todos|The pipeline failed')
      Todo::MARKED              | true  | s_('Todos|added a to-do item')
      Todo::APPROVAL_REQUIRED   | true  | format(s_("Todos|set %{who} as an approver"), who: s_('Todos|yourself'))
      Todo::APPROVAL_REQUIRED   | false | format(s_("Todos|set %{who} as an approver"), who: _('you'))
      Todo::UNMERGEABLE         | true  | s_('Todos|Could not merge')
      Todo::MERGE_TRAIN_REMOVED | true  | s_("Todos|Removed from Merge Train")
      Todo::REVIEW_SUBMITTED    | false | s_('Todos|reviewed your merge request')
    end

    with_them do
      before do
        alert_todo.action = action
        alert_todo.user = self_added? ? alert_todo.author : user
      end

      it { expect(helper.todo_action_name(alert_todo)).to eq(expected_action_name) }
    end

    context 'member access requested' do
      context 'when target is group' do
        it 'returns group access message' do
          group_todo.action = Todo::MEMBER_ACCESS_REQUESTED

          expect(helper.todo_action_name(group_todo)).to eq(
            format(s_("Todos|has requested access to group %{which}"), which: _(group.name))
          )
        end
      end

      context 'when target is project' do
        it 'returns project access message' do
          expect(helper.todo_action_name(project_access_request_todo)).to eq(
            format(s_("Todos|has requested access to project %{which}"), which: _(project.name))
          )
        end
      end
    end

    context 'okr checkin reminder' do
      it 'returns okr checkin reminder message' do
        alert_todo.action = Todo::OKR_CHECKIN_REQUESTED
        expect(helper.todo_action_name(alert_todo)).to eq(
          format(s_("Todos|requested an OKR update for %{what}"), what: alert_todo.target.title)
        )
      end
    end
  end

  describe '#todo_due_date' do
    subject(:result) { helper.todo_due_date(todo) }

    context 'due date is today' do
      let_it_be(:issue_with_today_due_date) do
        create(:issue, title: 'Issue 1', project: project, due_date: Date.current)
      end

      let(:todo) do
        create(:todo, project: issue_with_today_due_date.project, target: issue_with_today_due_date, note: note)
      end

      it { expect(result).to match('Due today') }
    end

    context 'due date is tomorrow' do
      let_it_be(:issue_with_tomorrow_due_date) do
        create(:issue, title: 'Issue 1', project: project, due_date: Date.tomorrow)
      end

      let(:todo) do
        create(:todo, project: issue_with_tomorrow_due_date.project, target: issue_with_tomorrow_due_date, note: note)
      end

      it { expect(result).to match("Due #{l(Date.tomorrow, format: Date::DATE_FORMATS[:medium])}") }
    end

    context 'due date is yesterday' do
      let_it_be(:issue_with_yesterday_due_date) do
        create(:issue, title: 'Issue 1', project: project, due_date: Date.yesterday)
      end

      let(:todo) do
        create(:todo, project: issue_with_yesterday_due_date.project, target: issue_with_yesterday_due_date, note: note)
      end

      it { expect(result).to match("Due #{l(Date.yesterday, format: Date::DATE_FORMATS[:medium])}") }
    end
  end

  describe '#todo_parent_path' do
    context 'when todo resource parent is a group' do
      subject(:result) { helper.todo_parent_path(group_todo) }

      it { expect(result).to eq(group_todo.group.name) }
    end

    context 'when todo resource parent is not a group' do
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
