# frozen_string_literal: true

shared_examples 'todo quick action' do |issuable_type|
  before do
    project.add_maintainer(maintainer)
    gitlab_sign_in(maintainer)
  end

  context "new #{issuable_type}", :js do
    before do
      case issuable_type
      when :merge_request
        visit public_send('namespace_project_new_merge_request_path', project.namespace, project, new_url_opts)
        wait_for_all_requests
      when :issue
        visit public_send('new_namespace_project_issue_path', project.namespace, project, new_url_opts)
        wait_for_all_requests
      end
    end

    it "creates the #{issuable_type} and interprets todo quick action accordingly" do
      fill_in "#{issuable_type}_title", with: 'bug 345'
      fill_in "#{issuable_type}_description", with: "bug description\n/todo"
      click_button "Submit #{issuable_type}".humanize

      issuable = project.public_send(issuable_type.to_s.pluralize).first

      expect(issuable.description).to eq 'bug description'
      expect(issuable).to be_opened
      expect(page).to have_content 'bug 345'
      expect(page).to have_content 'bug description'

      todos = TodosFinder.new(maintainer).execute
      expect(todos.size).to eq 0
    end
  end

  context "post note to existing #{issuable_type}" do
    before do
      visit public_send("project_#{issuable_type}_path", project, issuable)
      wait_for_all_requests
    end

    it 'creates the note and interprets the todo quick action accordingly' do
      add_note('/todo')

      wait_for_requests
      expect(page).not_to have_content '/todo'
      expect(page).to have_content 'Commands applied'

      todos = TodosFinder.new(maintainer).execute
      todo = todos.first

      expect(todos.size).to eq 1
      expect(todo).to be_pending
      expect(todo.target).to eq issuable
      expect(todo.author).to eq maintainer
      expect(todo.user).to eq maintainer
    end

    context "when current user cannot add todo #{issuable_type}" do
      before do
        guest = create(:user)
        project.add_guest(guest)

        gitlab_sign_out
        gitlab_sign_in(guest)
        visit public_send("project_#{issuable_type}_path", project, issuable)
        wait_for_all_requests
      end

      it "does not add todo the #{issuable_type}" do
        add_note('/todo')

        expect(page).not_to have_content 'Commands applied'
        todos = TodosFinder.new(maintainer).execute
        expect(todos.size).to eq 0
      end
    end
  end

  context "preview of note on #{issuable_type}", :js do
    it 'explains todo quick action' do
      visit public_send("project_#{issuable_type}_path", project, issuable)

      preview_note('/todo')

      expect(page).not_to have_content '/todo'
      expect(page).to have_content "Adds a todo."
    end
  end
end
