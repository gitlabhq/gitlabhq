# frozen_string_literal: true

shared_examples 'spend quick action' do |issuable_type|
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

    it "creates the #{issuable_type} and interprets spend quick action accordingly" do
      fill_in "#{issuable_type}_title", with: 'bug 345'
      fill_in "#{issuable_type}_description", with: "bug description\n/spend 1d 2h 3m"
      click_button "Submit #{issuable_type}".humanize

      issuable = project.public_send(issuable_type.to_s.pluralize).first

      expect(issuable.description).to eq 'bug description'
      expect(page).to have_content 'bug 345'
      expect(page).to have_content 'bug description'
      expect(issuable.total_time_spent).to eq 36180
    end
  end

  context "post note to existing #{issuable_type}" do
    before do
      visit public_send("project_#{issuable_type}_path", project, issuable)
      wait_for_all_requests
    end

    it 'creates the note and interprets the spend quick action accordingly' do
      add_note("/spend 1d 2h 3m")

      wait_for_requests
      expect(page).not_to have_content '/spend'
      expect(page).to have_content 'Commands applied'
      expect(issuable.reload.total_time_spent).to eq 36180
    end

    context "when current user cannot set spend time" do
      before do
        guest = create(:user)
        project.add_guest(guest)

        gitlab_sign_out
        gitlab_sign_in(guest)
        visit public_send("project_#{issuable_type}_path", project, issuable)
        wait_for_all_requests
      end

      it 'does not set spend time' do
        add_note("/spend 1s 2h 3m")

        wait_for_requests
        expect(page).not_to have_content '/spend'
        expect(issuable.reload.total_time_spent).to eq 0
      end
    end
  end

  context "preview of note on #{issuable_type}", :js do
    it 'explains spend quick action' do
      visit public_send("project_#{issuable_type}_path", project, issuable)

      preview_note('/spend 1d 2h 3m')

      expect(page).not_to have_content '/spend'
      expect(page).to have_content 'Adds 1d 2h 3m spent time.'
    end
  end
end
