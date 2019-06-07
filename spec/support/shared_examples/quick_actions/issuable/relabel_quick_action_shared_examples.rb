# frozen_string_literal: true

shared_examples 'relabel quick action' do |issuable_type|
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

    it "creates the #{issuable_type} and interprets relabel quick action accordingly" do
      fill_in "#{issuable_type}_title", with: 'bug 345'
      fill_in "#{issuable_type}_description", with: "bug description\n/label ~bug /relabel ~feature"
      click_button "Submit #{issuable_type}".humanize

      issuable = project.public_send(issuable_type.to_s.pluralize).first

      expect(issuable.description).to eq 'bug description'
      expect(issuable).to be_opened
      expect(page).to have_content 'bug 345'
      expect(page).to have_content 'bug description'
      expect(issuable.labels).to eq [label_bug, label_feature]
    end
  end

  context "post note to existing #{issuable_type}" do
    before do
      visit public_send("project_#{issuable_type}_path", project, issuable)
      wait_for_all_requests
      issuable.update(labels: [label_bug])
    end

    it 'creates the note and interprets the relabel quick action accordingly' do
      add_note('/relabel ~feature')

      wait_for_requests
      expect(page).not_to have_content '/relabel'
      expect(page).to have_content 'Commands applied'
      expect(issuable.reload.labels).to match_array([label_feature])
    end

    it 'creates the note and interprets the relabel quick action with empty param' do
      add_note('/relabel')

      wait_for_requests
      expect(page).not_to have_content '/relabel'
      expect(page).to have_content 'Commands applied'
      expect(issuable.reload.labels).to match_array([label_bug])
    end

    context "when current user cannot relabel to #{issuable_type}" do
      before do
        guest = create(:user)
        project.add_guest(guest)

        gitlab_sign_out
        gitlab_sign_in(guest)
        visit public_send("project_#{issuable_type}_path", project, issuable)
        wait_for_all_requests
      end

      it 'does not relabel' do
        add_note('/relabel ~feature')

        wait_for_requests
        expect(page).not_to have_content '/relabel'
        expect(issuable.labels).to match_array([label_bug])
      end
    end
  end

  context "preview of note on #{issuable_type}", :js do
    before do
      issuable.update(labels: [label_bug])
      visit public_send("project_#{issuable_type}_path", project, issuable)
    end

    it 'explains relabel all quick action' do
      preview_note('/relabel ~feature')

      expect(page).not_to have_content '/relabel'
      expect(page).to have_content 'Replaces all labels with feature label.'
    end
  end
end
