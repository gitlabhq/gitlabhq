# frozen_string_literal: true

RSpec.shared_examples 'rebase quick action' do
  context 'when updating the description' do
    before do
      sign_in(user)
      visit edit_project_merge_request_path(project, merge_request)
    end

    it 'rebases the MR', :sidekiq_inline do
      fill_in('Description', with: '/rebase')
      click_button('Save changes')

      expect(page).not_to have_content('commit behind the target branch')
      expect(merge_request.reload).not_to be_merged
    end

    it 'ignores /merge if /rebase is specified', :sidekiq_inline do
      fill_in('Description', with: "/merge\n/rebase")
      click_button('Save changes')

      expect(page).not_to have_content('commit behind the target branch')
      expect(merge_request.reload).not_to be_merged
    end
  end

  context 'when creating a new note' do
    context 'when the current user can rebase the MR' do
      before do
        sign_in(user)
        visit project_merge_request_path(project, merge_request)
      end

      it 'rebase the MR', :sidekiq_inline do
        add_note("/rebase")

        expect(page).to have_content "Scheduled a rebase of branch #{merge_request.source_branch}."
      end
    end

    context 'when the current user cannot rebase the MR' do
      before do
        project.add_guest(guest)
        sign_in(guest)
        visit project_merge_request_path(project, merge_request)
      end

      it 'does not rebase the MR' do
        add_note("/rebase")

        expect(page).not_to have_content 'Your commands have been executed!'
      end
    end
  end
end
