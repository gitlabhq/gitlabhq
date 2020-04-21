# frozen_string_literal: true

RSpec.shared_examples 'merge quick action' do
  context 'when the current user can merge the MR' do
    before do
      sign_in(user)
      visit project_merge_request_path(project, merge_request)
    end

    it 'merges the MR', :sidekiq_might_not_need_inline do
      add_note("/merge")

      expect(page).to have_content 'Merged this merge request.'

      expect(merge_request.reload).to be_merged
    end

    context 'when auto merge is avialable' do
      before do
        create(:ci_pipeline, :detached_merge_request_pipeline,
          project: project, merge_request: merge_request)
        merge_request.update_head_pipeline
      end

      it 'schedules to merge the MR' do
        add_note("/merge")

        expect(page).to have_content "Scheduled to merge this merge request (Merge when pipeline succeeds)."

        expect(merge_request.reload).to be_auto_merge_enabled
        expect(merge_request.reload).not_to be_merged
      end
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
