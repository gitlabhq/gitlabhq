# frozen_string_literal: true

shared_examples 'copy_metadata quick action' do |issuable_type|
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

    it "creates the #{issuable_type} and interprets copy_metadata quick action accordingly" do
      fill_in "#{issuable_type}_title", with: 'bug 345'
      fill_in "#{issuable_type}_description", with: "bug description\n/copy_metadata #{source_issuable.to_reference(project)}"
      click_button "Submit #{issuable_type}".humanize

      issuable = project.public_send(issuable_type.to_s.pluralize).last

      expect(page).to have_content 'bug 345'
      expect(page).to have_content 'bug description'
      issuable.reload
      expect(issuable.description).to eq 'bug description'
      expect(issuable.milestone).to eq milestone
      expect(issuable.labels).to match_array([label_bug, label_feature])
    end
  end

  context "post note to existing #{issuable_type}" do
    before do
      visit public_send("project_#{issuable_type}_path", project, issuable)
      wait_for_all_requests
    end

    it 'creates the note and interprets copy_metadata quick action accordingly' do
      add_note("/copy_metadata #{source_issuable.to_reference(project)}")

      wait_for_requests
      expect(page).not_to have_content '/copy_metadata'
      expect(page).to have_content 'Commands applied'
      issuable.reload
      expect(issuable.milestone).to eq milestone
      expect(issuable.labels).to match_array([label_bug, label_feature])
    end

    context "when current user cannot copy_metadata" do
      before do
        guest = create(:user)
        project.add_guest(guest)

        gitlab_sign_out
        gitlab_sign_in(guest)
        visit public_send("project_#{issuable_type}_path", project, issuable)
        wait_for_all_requests
      end

      it 'does not copy_metadata' do
        add_note("/copy_metadata #{source_issuable.to_reference(project)}")

        wait_for_requests
        expect(page).not_to have_content '/copy_metadata'
        expect(page).not_to have_content 'Commands applied'
        issuable.reload
        expect(issuable.milestone).not_to eq milestone
        expect(issuable.labels).to eq []
      end
    end
  end

  context "preview of note on #{issuable_type}", :js do
    it 'explains copy_metadata quick action' do
      visit public_send("project_#{issuable_type}_path", project, issuable)

      preview_note("/copy_metadata #{source_issuable.to_reference(project)}")

      expect(page).not_to have_content '/copy_metadata'
      expect(page).to have_content "Copy labels and milestone from #{source_issuable.to_reference(project)}."
    end
  end
end
