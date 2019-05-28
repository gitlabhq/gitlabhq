# frozen_string_literal: true

shared_examples 'done quick action' do |issuable_type|
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

    it "creates the #{issuable_type} and interprets done quick action accordingly" do
      fill_in "#{issuable_type}_title", with: 'bug 345'
      fill_in "#{issuable_type}_description", with: "bug description\n/done"
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
      TodoService.new.mark_todo(issuable, maintainer)
      visit public_send("project_#{issuable_type}_path", project, issuable)
      wait_for_all_requests
    end

    it 'creates the note and interprets the done quick action accordingly' do
      todos = TodosFinder.new(maintainer).execute
      todo = todos.first
      expect(todo.reload).to be_pending

      expect(todos.size).to eq 1
      expect(todo.target).to eq issuable
      expect(todo.author).to eq maintainer
      expect(todo.user).to eq maintainer

      add_note('/done')

      wait_for_requests
      expect(page).not_to have_content '/done'
      expect(page).to have_content 'Commands applied'
      expect(todo.reload).to be_done
    end

    context "when current user cannot mark #{issuable_type} todo as done" do
      before do
        guest = create(:user)
        project.add_guest(guest)

        gitlab_sign_out
        gitlab_sign_in(guest)
        visit public_send("project_#{issuable_type}_path", project, issuable)
        wait_for_all_requests
      end

      it "does not set the #{issuable_type} todo as done" do
        todos = TodosFinder.new(maintainer).execute
        todo = todos.first
        expect(todo.reload).to be_pending

        expect(todos.size).to eq 1
        expect(todo.target).to eq issuable
        expect(todo.author).to eq maintainer
        expect(todo.user).to eq maintainer

        add_note('/done')

        expect(page).not_to have_content 'Commands applied'
        expect(todo.reload).to be_pending
      end
    end
  end

  context "preview of note on #{issuable_type}", :js do
    it 'explains done quick action' do
      TodoService.new.mark_todo(issuable, maintainer)
      visit public_send("project_#{issuable_type}_path", project, issuable)

      preview_note('/done')

      expect(page).not_to have_content '/done'
      expect(page).to have_content "Marks todo as done."
    end
  end
end
