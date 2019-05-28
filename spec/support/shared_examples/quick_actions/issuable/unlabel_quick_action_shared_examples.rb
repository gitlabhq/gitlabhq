# frozen_string_literal: true

shared_examples 'unlabel quick action' do |issuable_type|
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

    it "creates the #{issuable_type} and interprets unlabel quick action accordingly" do
      fill_in "#{issuable_type}_title", with: 'bug 345'
      fill_in "#{issuable_type}_description", with: "bug description\n/label ~bug /unlabel"
      click_button "Submit #{issuable_type}".humanize

      issuable = project.public_send(issuable_type.to_s.pluralize).first

      expect(issuable.description).to eq 'bug description'
      expect(issuable).to be_opened
      expect(page).to have_content 'bug 345'
      expect(page).to have_content 'bug description'
      expect(issuable.labels).to eq [label_bug]
    end
  end

  context "post note to existing #{issuable_type}" do
    before do
      visit public_send("project_#{issuable_type}_path", project, issuable)
      wait_for_all_requests
      issuable.update(labels: [label_bug, label_feature])
    end

    it 'creates the note and interprets the unlabel all quick action accordingly' do
      add_note("/unlabel")

      wait_for_requests
      expect(page).not_to have_content '/unlabel'
      expect(page).to have_content 'Commands applied'
      expect(issuable.reload.labels).to eq []
    end

    it 'creates the note and interprets the unlabel some quick action accordingly' do
      add_note("/unlabel ~bug")

      wait_for_requests
      expect(page).not_to have_content '/unlabel'
      expect(page).to have_content 'Commands applied'
      expect(issuable.reload.labels).to match_array([label_feature])
    end

    context "when current user cannot unlabel to #{issuable_type}" do
      before do
        guest = create(:user)
        project.add_guest(guest)

        gitlab_sign_out
        gitlab_sign_in(guest)
        visit public_send("project_#{issuable_type}_path", project, issuable)
        wait_for_all_requests
      end

      it 'does not unlabel' do
        add_note("/unlabel")

        wait_for_requests
        expect(page).not_to have_content '/unlabel'
        expect(issuable.labels).to match_array([label_bug, label_feature])
      end
    end
  end

  context "preview of note on #{issuable_type}", :js do
    before do
      issuable.update(labels: [label_bug, label_feature])
      visit public_send("project_#{issuable_type}_path", project, issuable)
    end

    it 'explains unlabel all quick action' do
      preview_note('/unlabel')

      expect(page).not_to have_content '/unlabel'
      expect(page).to have_content 'Removes all labels.'
    end

    it 'explains unlabel some quick action' do
      preview_note('/unlabel ~bug')

      expect(page).not_to have_content '/unlabel'
      expect(page).to have_content 'Removes bug label.'
    end
  end
end
