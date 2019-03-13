# frozen_string_literal: true

shared_examples 'assign quick action' do |issuable_type|
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

    it "creates the #{issuable_type} and interprets assign quick action accordingly" do
      assignee = create(:user, username: 'bob')

      fill_in "#{issuable_type}_title", with: 'bug 345'
      fill_in "#{issuable_type}_description", with: "bug description\n/assign @bob"
      click_button "Submit #{issuable_type}".humanize

      issuable = project.public_send(issuable_type.to_s.pluralize).first

      expect(issuable.description).to eq 'bug description'
      expect(issuable.assignees).to eq [assignee]
      expect(page).to have_content 'bug 345'
      expect(page).to have_content 'bug description'
    end

    it "creates the #{issuable_type} and interprets assign quick action accordingly" do
      fill_in "#{issuable_type}_title", with: 'bug 345'
      fill_in "#{issuable_type}_description", with: "bug description\n/assign me"
      click_button "Submit #{issuable_type}".humanize

      issuable = project.public_send(issuable_type.to_s.pluralize).first

      expect(issuable.description).to eq 'bug description'
      expect(issuable.assignees).to eq [maintainer]
      expect(page).to have_content 'bug 345'
      expect(page).to have_content 'bug description'
    end
  end

  context "post note to existing #{issuable_type}" do
    before do
      visit public_send("project_#{issuable_type}_path", project, issuable)
      wait_for_all_requests
    end

    it 'creates the note and interprets the assign quick action accordingly' do
      assignee = create(:user, username: 'bob')
      add_note("Awesome!\n\n/assign @bob")

      expect(page).to have_content 'Awesome!'
      expect(page).not_to have_content '/assign @bob'

      wait_for_requests
      issuable.reload
      note = issuable.notes.user.first

      expect(note.note).to eq 'Awesome!'
      expect(issuable.assignees).to eq [assignee]
    end

    it "assigns the #{issuable_type} to the current user" do
      add_note("/assign me")

      expect(page).not_to have_content '/assign me'
      expect(page).to have_content 'Commands applied'

      expect(issuable.reload.assignees).to eq [maintainer]
    end
  end

  context "preview of note on #{issuable_type}", :js do
    it 'explains assign quick action to bob' do
      create(:user, username: 'bob')

      visit public_send("project_#{issuable_type}_path", project, issuable)

      page.within('.js-main-target-form') do
        fill_in 'note[note]', with: "Awesome!\n/assign @bob "
        click_on 'Preview'

        expect(page).not_to have_content '/assign @bob'
        expect(page).to have_content 'Awesome!'
        expect(page).to have_content 'Assigns @bob.'
      end
    end

    it 'explains assign quick action to me' do
      visit public_send("project_#{issuable_type}_path", project, issuable)

      page.within('.js-main-target-form') do
        fill_in 'note[note]', with: "Awesome!\n/assign me"
        click_on 'Preview'

        expect(page).not_to have_content '/assign me'
        expect(page).to have_content 'Awesome!'
        expect(page).to have_content "Assigns @#{maintainer.username}."
      end
    end
  end
end
