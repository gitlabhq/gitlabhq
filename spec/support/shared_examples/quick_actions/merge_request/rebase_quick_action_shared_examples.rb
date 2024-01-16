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

      context 'when the merge request is closed' do
        before do
          merge_request.close!
        end

        it 'does not rebase the MR', :sidekiq_inline do
          add_note("/rebase")

          expect(page).not_to have_content 'Scheduled a rebase'
        end
      end

      context 'when a rebase is in progress', :sidekiq_inline, :clean_gitlab_redis_shared_state do
        before do
          jid = SecureRandom.hex
          merge_request.update!(rebase_jid: jid)
          Gitlab::SidekiqStatus.set(jid)
        end

        it 'tells the user a rebase is in progress' do
          add_note('/rebase')

          expect(page).to have_content Gitlab::QuickActions::MergeRequestActions::REBASE_FAILURE_REBASE_IN_PROGRESS
          expect(page).not_to have_content 'Scheduled a rebase'
        end
      end

      context 'when there are conflicts in the merge request' do
        let!(:merge_request) { create(:merge_request, source_project: project, target_project: project, source_branch: 'conflict-missing-side', target_branch: 'conflict-start', merge_status: :cannot_be_merged) }

        it 'does not rebase the MR' do
          add_note("/rebase")

          expect(page).to have_content Gitlab::QuickActions::MergeRequestActions::REBASE_FAILURE_UNMERGEABLE
        end
      end

      context 'when the merge request branch is protected from force push' do
        let!(:protected_branch) do
          ProtectedBranches::CreateService.new(
            project,
            user,
            name: merge_request.source_branch,
            allow_force_push: false,
            push_access_levels_attributes: [{ access_level: Gitlab::Access::DEVELOPER }],
            merge_access_levels_attributes: [{ access_level: Gitlab::Access::DEVELOPER }]
          ).execute
        end

        it 'does not rebase the MR' do
          add_note("/rebase")

          expect(page).to have_content Gitlab::QuickActions::MergeRequestActions::REBASE_FAILURE_PROTECTED_BRANCH
        end
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

        expect(page).not_to have_content 'Scheduled a rebase'
      end
    end
  end
end
