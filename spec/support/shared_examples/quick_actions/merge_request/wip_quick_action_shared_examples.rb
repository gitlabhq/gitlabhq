# frozen_string_literal: true

shared_examples 'wip quick action' do
  context 'when the current user can toggle the WIP prefix' do
    before do
      sign_in(user)
      visit project_merge_request_path(project, merge_request)
      wait_for_requests
    end

    it 'adds the WIP: prefix to the title' do
      add_note('/wip')

      expect(page).not_to have_content '/wip'
      expect(page).to have_content 'Commands applied'

      expect(merge_request.reload.work_in_progress?).to eq true
    end

    it 'removes the WIP: prefix from the title' do
      merge_request.update!(title: merge_request.wip_title)
      add_note('/wip')

      expect(page).not_to have_content '/wip'
      expect(page).to have_content 'Commands applied'

      expect(merge_request.reload.work_in_progress?).to eq false
    end
  end

  context 'when the current user cannot toggle the WIP prefix' do
    before do
      project.add_guest(guest)
      sign_in(guest)
      visit project_merge_request_path(project, merge_request)
    end

    it 'does not change the WIP prefix' do
      add_note('/wip')

      expect(page).not_to have_content '/wip'
      expect(page).not_to have_content 'Commands applied'

      expect(merge_request.reload.work_in_progress?).to eq false
    end
  end
end
