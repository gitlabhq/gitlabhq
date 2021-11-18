# frozen_string_literal: true

RSpec.shared_examples 'promote_to_incident quick action' do
  describe '/promote_to_incident' do
    context 'when issue can be promoted' do
      it 'promotes issue to incident' do
        add_note('/promote_to_incident')

        expect(issue.reload.issue_type).to eq('incident')
        expect(page).to have_content('Issue has been promoted to incident')
      end
    end

    context 'when issue is already an incident' do
      let(:issue) { create(:incident, project: project) }

      it 'does not promote the issue' do
        add_note('/promote_to_incident')

        expect(page).to have_content('Could not apply promote_to_incident command')
      end
    end

    context 'when user does not have permissions' do
      let(:guest) { create(:user) }

      before do
        sign_in(guest)
        visit project_issue_path(project, issue)
        wait_for_all_requests
      end

      it 'does not promote the issue' do
        add_note('/promote_to_incident')

        expect(page).to have_content('Could not apply promote_to_incident command')
      end
    end
  end
end
