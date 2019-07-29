# frozen_string_literal: true

shared_examples 'merge quick action' do
  context 'when the current user can merge the MR' do
    before do
      sign_in(user)
      visit project_merge_request_path(project, merge_request)
    end

    it 'merges the MR' do
      add_note("/merge")

      expect(page).to have_content 'Scheduled to merge this merge request when the pipeline succeeds.'

      expect(merge_request.reload).to be_merged
    end
  end

  context 'when the head diff changes in the meanwhile' do
    before do
      merge_request.source_branch = 'another_branch'
      merge_request.save
      sign_in(user)
      visit project_merge_request_path(project, merge_request)
    end

    it 'does not merge the MR' do
      add_note("/merge")

      expect(page).not_to have_content 'Your commands have been executed!'

      expect(merge_request.reload).not_to be_merged
    end
  end

  context 'when the current user cannot merge the MR' do
    before do
      project.add_guest(guest)
      sign_in(guest)
      visit project_merge_request_path(project, merge_request)
    end

    it 'does not merge the MR' do
      add_note("/merge")

      expect(page).not_to have_content 'Your commands have been executed!'

      expect(merge_request.reload).not_to be_merged
    end
  end
end
