# frozen_string_literal: true

RSpec.shared_examples 'promote_to_incident quick action' do
  include ListboxHelpers

  describe '/promote_to_incident' do
    context 'when issue can be promoted' do
      it 'promotes issue to incident' do
        fill_in('Add a reply', with: '/promote_to_incident')
        click_button 'Comment'

        expect(issue.reload.issue_type).to eq('incident')
        # Page does full refresh, so check the work item type
        expect(page).to have_css('[data-testid="work-item-type-icon"]', text: 'Incident')
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
      end

      it 'does not promote the issue' do
        fill_in('Add a reply', with: '/promote_to_incident')
        click_button 'Comment'

        # Page does full refresh, so check the work item type
        expect(page).to have_css('[data-testid="work-item-type-icon"]', text: 'Issue')
      end
    end

    context 'on issue creation' do
      it 'promotes issue to incident' do
        visit new_project_issue_path(project)
        fill_in('Title', with: 'Title')
        fill_in('Description', with: '/promote_to_incident')
        click_button('Create issue')

        expect(page).to have_content("Incident created just now by #{user.name}")
      end

      context 'when incident is selected for issue type' do
        it 'promotes issue to incident' do
          visit new_project_issue_path(project)

          select 'Incident', from: 'Type'
          fill_in('Title', with: 'Title')
          fill_in('Description', with: '/promote_to_incident')
          click_button('Create incident')

          expect(page).to have_content("Incident created just now by #{user.name}")
        end
      end
    end
  end
end
