# frozen_string_literal: true

shared_examples 'unassign quick action' do |issuable_type|
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

    it "creates the #{issuable_type} and interprets unassign quick action accordingly" do
      fill_in "#{issuable_type}_title", with: 'bug 345'
      fill_in "#{issuable_type}_description", with: "bug description\n/unassign @bob"
      click_button "Submit #{issuable_type}".humanize

      issuable = project.public_send(issuable_type.to_s.pluralize).first

      expect(issuable.description).to eq 'bug description'
      expect(issuable.assignees).to eq []
      expect(page).to have_content 'bug 345'
      expect(page).to have_content 'bug description'
    end

    it "creates the #{issuable_type} and interprets unassign quick action accordingly" do
      fill_in "#{issuable_type}_title", with: 'bug 345'
      fill_in "#{issuable_type}_description", with: "bug description\n/unassign me"
      click_button "Submit #{issuable_type}".humanize

      issuable = project.public_send(issuable_type.to_s.pluralize).first

      expect(issuable.description).to eq 'bug description'
      expect(issuable.assignees).to eq []
      expect(page).to have_content 'bug 345'
      expect(page).to have_content 'bug description'
    end
  end

  context "post note to existing #{issuable_type}" do
    before do
      visit public_send("project_#{issuable_type}_path", project, issuable)
      wait_for_all_requests
    end

    it 'creates the note and interprets the unassign quick action accordingly' do
      assignee = create(:user, username: 'bob')
      issuable.update(assignee_ids: [assignee.id])
      expect(issuable.assignees).to eq [assignee]

      add_note("Awesome!\n\n/unassign @bob")

      expect(page).to have_content 'Awesome!'
      expect(page).not_to have_content '/unassign @bob'

      wait_for_requests
      issuable.reload
      note = issuable.notes.user.first

      expect(note.note).to eq 'Awesome!'
      expect(issuable.assignees).to eq []
    end

    it "unassigns the #{issuable_type} from current user" do
      issuable.update(assignee_ids: [maintainer.id])
      expect(issuable.reload.assignees).to eq [maintainer]
      expect(issuable.assignees).to eq [maintainer]

      add_note("/unassign me")

      expect(page).not_to have_content '/unassign me'
      expect(page).to have_content 'Commands applied'

      expect(issuable.reload.assignees).to eq []
    end
  end

  context "preview of note on #{issuable_type}", :js do
    it 'explains unassign quick action: from bob' do
      assignee = create(:user, username: 'bob')
      issuable.update(assignee_ids: [assignee.id])
      expect(issuable.assignees).to eq [assignee]

      visit public_send("project_#{issuable_type}_path", project, issuable)

      page.within('.js-main-target-form') do
        fill_in 'note[note]', with: "Awesome!\n/unassign @bob "
        click_on 'Preview'

        expect(page).not_to have_content '/unassign @bob'
        expect(page).to have_content 'Awesome!'
        expect(page).to have_content 'Removes assignee @bob.'
      end
    end

    it 'explains unassign quick action: from me' do
      issuable.update(assignee_ids: [maintainer.id])
      expect(issuable.assignees).to eq [maintainer]

      visit public_send("project_#{issuable_type}_path", project, issuable)

      page.within('.js-main-target-form') do
        fill_in 'note[note]', with: "Awesome!\n/unassign me"
        click_on 'Preview'

        expect(page).not_to have_content '/unassign me'
        expect(page).to have_content 'Awesome!'
        expect(page).to have_content "Removes assignee @#{maintainer.username}."
      end
    end
  end
end
