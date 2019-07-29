# frozen_string_literal: true

shared_examples 'duplicate quick action' do
  context 'mark issue as duplicate' do
    let(:original_issue) { create(:issue, project: project) }

    context 'when the current user can update issues' do
      it 'does not create a note, and marks the issue as a duplicate' do
        add_note("/duplicate ##{original_issue.to_reference}")

        expect(page).not_to have_content "/duplicate #{original_issue.to_reference}"
        expect(page).to have_content "marked this issue as a duplicate of #{original_issue.to_reference}"

        expect(issue.reload).to be_closed
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

      it 'does not create a note, and does not mark the issue as a duplicate' do
        add_note("/duplicate ##{original_issue.to_reference}")

        expect(page).not_to have_content "marked this issue as a duplicate of #{original_issue.to_reference}"

        expect(issue.reload).to be_open
      end
    end
  end
end
