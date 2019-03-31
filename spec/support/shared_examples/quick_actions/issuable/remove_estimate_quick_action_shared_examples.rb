# frozen_string_literal: true

shared_examples 'remove_estimate quick action' do |issuable_type|
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

    it "creates the #{issuable_type} and interprets estimate quick action accordingly" do
      fill_in "#{issuable_type}_title", with: 'bug 345'
      fill_in "#{issuable_type}_description", with: "bug description\n/remove_estimate"
      click_button "Submit #{issuable_type}".humanize

      issuable = project.public_send(issuable_type.to_s.pluralize).first

      expect(issuable.description).to eq 'bug description'
      expect(page).to have_content 'bug 345'
      expect(page).to have_content 'bug description'
      expect(issuable.time_estimate).to eq 0
    end
  end

  context "post note to existing #{issuable_type}" do
    before do
      visit public_send("project_#{issuable_type}_path", project, issuable)
      wait_for_all_requests
      issuable.update_attribute(:time_estimate, 36180)
    end

    it 'creates the note and interprets the remove_estimate quick action accordingly' do
      add_note("/remove_estimate")

      wait_for_requests
      expect(page).not_to have_content '/remove_estimate'
      expect(page).to have_content 'Commands applied'
      expect(issuable.reload.time_estimate).to eq 0
    end

    context "when current user cannot remove_estimate" do
      before do
        guest = create(:user)
        project.add_guest(guest)

        gitlab_sign_out
        gitlab_sign_in(guest)
        visit public_send("project_#{issuable_type}_path", project, issuable)
        wait_for_all_requests
      end

      it 'does not remove_estimate' do
        add_note('/remove_estimate')

        wait_for_requests
        expect(page).not_to have_content '/remove_estimate'
        expect(issuable.reload.time_estimate).to eq 36180
      end
    end
  end

  context "preview of note on #{issuable_type}", :js do
    it 'explains remove_estimate quick action' do
      visit public_send("project_#{issuable_type}_path", project, issuable)

      preview_note('/remove_estimate')

      expect(page).not_to have_content '/remove_estimate'
      expect(page).to have_content 'Removes time estimate.'
    end
  end
end
