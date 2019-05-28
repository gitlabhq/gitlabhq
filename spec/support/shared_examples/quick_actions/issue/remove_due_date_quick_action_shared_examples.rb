# frozen_string_literal: true

shared_examples 'remove_due_date quick action' do
  context 'remove_due_date action available and due date can be removed' do
    it 'removes the due date accordingly' do
      add_note('/remove_due_date')

      expect(page).not_to have_content '/remove_due_date'
      expect(page).to have_content 'Commands applied'

      visit project_issue_path(project, issue)

      page.within '.due_date' do
        expect(page).to have_content 'None'
      end
    end
  end

  context 'remove_due_date action not available' do
    let(:guest) { create(:user) }
    before do
      project.add_guest(guest)
      gitlab_sign_out
      sign_in(guest)
      visit project_issue_path(project, issue)
    end

    it 'does not remove the due date' do
      add_note("/remove_due_date")

      expect(page).not_to have_content 'Commands applied'
      expect(page).not_to have_content '/remove_due_date'
    end
  end
end
