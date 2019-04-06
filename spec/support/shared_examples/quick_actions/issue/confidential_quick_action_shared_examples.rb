# frozen_string_literal: true

shared_examples 'confidential quick action' do
  context 'when the current user can update issues' do
    it 'does not create a note, and marks the issue as confidential' do
      add_note('/confidential')

      expect(page).not_to have_content '/confidential'
      expect(page).to have_content 'Commands applied'
      expect(page).to have_content 'made the issue confidential'

      expect(issue.reload).to be_confidential
    end
  end

  context 'when the current user cannot update the issue' do
    let(:guest) { create(:user) }

    before do
      project.add_guest(guest)
      gitlab_sign_out
      sign_in(guest)
      visit project_issue_path(project, issue)
    end

    it 'does not create a note, and does not mark the issue as confidential' do
      add_note('/confidential')

      expect(page).not_to have_content 'Commands applied'
      expect(page).not_to have_content 'made the issue confidential'

      expect(issue.reload).not_to be_confidential
    end
  end
end
