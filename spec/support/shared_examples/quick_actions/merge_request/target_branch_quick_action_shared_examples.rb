# frozen_string_literal: true

shared_examples 'target_branch quick action' do
  describe '/target_branch command in merge request' do
    let(:another_project) { create(:project, :public, :repository) }
    let(:new_url_opts) { { merge_request: { source_branch: 'feature' } } }

    before do
      another_project.add_maintainer(user)
      sign_in(user)
    end

    it 'changes target_branch in new merge_request' do
      visit project_new_merge_request_path(another_project, new_url_opts)

      fill_in "merge_request_title", with: 'My brand new feature'
      fill_in "merge_request_description", with: "le feature \n/target_branch fix\nFeature description:"
      click_button "Submit merge request"

      merge_request = another_project.merge_requests.first
      expect(merge_request.description).to eq "le feature \nFeature description:"
      expect(merge_request.target_branch).to eq 'fix'
    end

    it 'does not change target branch when merge request is edited' do
      new_merge_request = create(:merge_request, source_project: another_project)

      visit edit_project_merge_request_path(another_project, new_merge_request)
      fill_in "merge_request_description", with: "Want to update target branch\n/target_branch fix\n"
      click_button "Save changes"

      new_merge_request = another_project.merge_requests.first
      expect(new_merge_request.description).to include('/target_branch')
      expect(new_merge_request.target_branch).not_to eq('fix')
    end
  end

  describe '/target_branch command from note' do
    context 'when the current user can change target branch' do
      before do
        sign_in(user)
        visit project_merge_request_path(project, merge_request)
      end

      it 'changes target branch from a note' do
        add_note("message start \n/target_branch merge-test\n message end.")

        wait_for_requests
        expect(page).not_to have_content('/target_branch')
        expect(page).to have_content('message start')
        expect(page).to have_content('message end.')

        expect(merge_request.reload.target_branch).to eq 'merge-test'
      end

      it 'does not fail when target branch does not exists' do
        add_note('/target_branch totally_not_existing_branch')

        expect(page).not_to have_content('/target_branch')

        expect(merge_request.target_branch).to eq 'feature'
      end
    end

    context 'when current user can not change target branch' do
      before do
        project.add_guest(guest)
        sign_in(guest)
        visit project_merge_request_path(project, merge_request)
      end

      it 'does not change target branch' do
        add_note('/target_branch merge-test')

        expect(page).not_to have_content '/target_branch merge-test'

        expect(merge_request.target_branch).to eq 'feature'
      end
    end
  end
end
