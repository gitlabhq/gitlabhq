# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TodosHelper do
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

  describe '#todo_target_state_pill' do
    subject { helper.todo_target_state_pill(todo) }

    shared_examples 'a rendered state pill' do |attr|
      it 'returns expected html' do
        aggregate_failures do
          expect(subject).to have_css(".status-box-#{attr[:type]}-#{attr[:state].dasherize}")
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

      context 'merged MR' do
        before do
          todo.target.update!(state: 'merged')
        end

        it_behaves_like 'a rendered state pill', type: 'mr', state: 'merged'
      end
    end

    context 'issue todo' do
      let(:todo) { create(:todo, target: issue) }

      it_behaves_like 'no state pill'

      context 'closed issue' do
        before do
          todo.target.update!(state: 'closed')
        end

        it_behaves_like 'a rendered state pill', type: 'issue', state: 'closed'
      end
    end

    context 'alert todo' do
      let(:todo) { alert_todo }

      it_behaves_like 'no state pill'

      context 'resolved alert' do
        before do
          todo.target.resolve!
        end

        it_behaves_like 'a rendered state pill', type: 'alert', state: 'resolved'
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
end
