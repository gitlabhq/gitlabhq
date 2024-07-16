# frozen_string_literal: true

RSpec.shared_examples 'merge quick action' do
  context 'when updating the description' do
    before do
      sign_in(user)
      visit edit_project_merge_request_path(project, merge_request)
    end

    it 'merges the MR', :sidekiq_inline do
      fill_in('Description', with: '/merge')
      click_button('Save changes')

      expect(page).to have_content('Merged')
      expect(merge_request.reload).to be_merged
    end
  end

  context 'when creating a new note' do
    context 'when the current user can merge the MR' do
      before do
        sign_in(user)
        visit project_merge_request_path(project, merge_request)
      end

      it 'merges the MR', :sidekiq_inline do
        add_note("/merge")

        expect(page).to have_content 'Merged this merge request.'

        expect(merge_request.reload).to be_merged
      end

      context 'when auto merge is available' do
        before do
          create(:ci_pipeline, :detached_merge_request_pipeline,
            project: project, merge_request: merge_request)
          merge_request.update_head_pipeline

          stub_licensed_features(merge_request_approvers: true) if Gitlab.ee?
        end

        it 'schedules to merge the MR' do
          add_note("/merge")

          expect(page).to(
            have_content("Scheduled to merge this merge request (Merge when checks pass).")
          )

          expect(merge_request.reload).to be_auto_merge_enabled
          expect(merge_request.reload).not_to be_merged
        end
      end
    end

    context 'when the head diff changes in the meanwhile' do
      before do
        merge_request.source_branch = 'another_branch'
        merge_request.save!
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
end
