# frozen_string_literal: true

shared_examples 'reopen quick action' do |issuable_type|
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

    it "creates the #{issuable_type} and interprets reopen quick action accordingly" do
      fill_in "#{issuable_type}_title", with: 'bug 345'
      fill_in "#{issuable_type}_description", with: "bug description\n/reopen"
      click_button "Submit #{issuable_type}".humanize

      issuable = project.public_send(issuable_type.to_s.pluralize).first

      expect(issuable.description).to eq 'bug description'
      expect(issuable).to be_opened
      expect(page).to have_content 'bug 345'
      expect(page).to have_content 'bug description'
    end
  end

  context "post note to existing #{issuable_type}" do
    before do
      issuable.close
      expect(issuable).to be_closed
      visit public_send("project_#{issuable_type}_path", project, issuable)
      wait_for_all_requests
    end

    it 'creates the note and interprets the reopen quick action accordingly' do
      add_note('/reopen')

      wait_for_requests
      expect(page).not_to have_content '/reopen'
      expect(page).to have_content 'Commands applied'

      issuable.reload
      expect(issuable).to be_opened
    end

    context "when current user cannot reopen #{issuable_type}" do
      before do
        guest = create(:user)
        project.add_guest(guest)

        gitlab_sign_out
        gitlab_sign_in(guest)
        visit public_send("project_#{issuable_type}_path", project, issuable)
        wait_for_all_requests
      end

      it "does not reopen the #{issuable_type}" do
        add_note('/reopen')

        expect(page).not_to have_content 'Commands applied'
        expect(issuable).to be_closed
      end
    end
  end

  context "preview of note on #{issuable_type}", :js do
    it 'explains reopen quick action' do
      issuable.close
      expect(issuable).to be_closed
      visit public_send("project_#{issuable_type}_path", project, issuable)

      preview_note('/reopen')

      expect(page).not_to have_content '/reopen'
      expect(page).to have_content "Reopens this #{issuable_type.to_s.humanize.downcase}."
    end
  end
end
