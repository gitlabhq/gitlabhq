# frozen_string_literal: true

RSpec.shared_examples 'clone quick action' do
  before do
    allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(150)
  end

  context 'clone the issue to another project' do
    let(:target_project) { create(:project, :public) }

    context 'when no target is given' do
      it 'clones the issue in the current project' do
        fill_in('Add a reply', with: '/clone')
        click_button 'Comment'

        expect(page).to have_content "Cloned this item to #{project.full_path}."
        expect(issue.reload).to be_open

        visit project_issue_path(project, issue)

        expect(page).to have_content issue.title
      end
    end

    context 'when the project is valid' do
      before do
        target_project.add_maintainer(user)
      end

      it 'clones the issue' do
        fill_in('Add a reply', with: "/clone #{target_project.full_path}")
        click_button 'Comment'

        expect(page).to have_content "Cloned this item to #{target_project.full_path}."
        expect(issue.reload).to be_open

        visit project_issue_path(target_project, issue)

        expect(page).to have_content issue.title
      end

      context 'when cloning with notes', :aggregate_failures do
        it 'clones the issue with all notes' do
          fill_in('Add a reply', with: 'Some random note')
          click_button 'Comment'
          fill_in('Add a reply', with: 'Another note')
          click_button 'Comment'
          fill_in('Add a reply', with: "/clone --with_notes #{target_project.full_path}")
          click_button 'Comment'

          expect(page).to have_content "Cloned this item to #{target_project.full_path}."
          expect(issue.reload).to be_open

          visit project_issue_path(target_project, issue)

          expect(page).to have_content issue.title
          expect(page).to have_content 'Some random note'
          expect(page).to have_content 'Another note'
        end

        it 'returns an error if the params are malformed' do
          # Note that this is missing one `-`
          fill_in('Add a reply', with: "/clone -with_notes #{target_project.full_path}")
          click_button 'Comment'

          expect(page).to have_content 'Failed to clone this item: wrong parameters.'
          expect(issue.reload).to be_open
        end
      end
    end

    context 'when the project is valid but the user not authorized' do
      let(:project_unauthorized) { create(:project, :public) }

      it 'does not clone the issue' do
        fill_in('Add a reply', with: "/clone #{project_unauthorized.full_path}")
        click_button 'Comment'

        expect(page).to have_content "Unable to clone. Insufficient permissions."
        expect(issue.reload).to be_open

        visit project_issue_path(target_project, issue)

        expect(page).not_to have_content issue.title
      end
    end

    context 'when the project is invalid' do
      it 'does not clone the issue' do
        fill_in('Add a reply', with: '/clone not/valid')
        click_button 'Comment'

        expect(page).to have_content "Unable to clone. Target project or group doesn't exist or doesn't support this item type."
        expect(issue.reload).to be_open
      end
    end

    context 'when the user issues multiple commands' do
      let(:milestone) { create(:milestone, title: '1.0', project: project) }
      let(:bug)      { create(:label, project: project, title: 'bug') }
      let(:wontfix)  { create(:label, project: project, title: 'wontfix') }

      before do
        allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(250)
        target_project.add_maintainer(user)

        # create equivalent labels and milestones in the target project
        create(:label, project: target_project, title: 'bug')
        create(:label, project: target_project, title: 'wontfix')
        create(:milestone, title: '1.0', project: target_project)
      end

      shared_examples 'applies the commands to issues in both projects, target and source' do
        it "applies quick actions" do
          expect(page).to have_content "Cloned this item to #{target_project.full_path}."
          expect(issue.reload).to be_open

          visit project_issue_path(target_project, issue)

          expect(page).to have_content 'bug'
          expect(page).to have_content 'wontfix'
          expect(page).to have_content '1.0'

          visit project_issue_path(project, issue)
          expect(page).to have_content 'bug'
          expect(page).to have_content 'wontfix'
          expect(page).to have_content '1.0'
        end
      end

      context 'applies multiple commands with clone command in the end' do
        before do
          fill_in('Add a reply', with: "/label ~#{bug.title} ~#{wontfix.title}\n\n/milestone %\"#{milestone.title}\"\n\n/clone #{target_project.full_path}")
          click_button 'Comment'
        end

        it_behaves_like 'applies the commands to issues in both projects, target and source'
      end

      context 'applies multiple commands with clone command in the begining' do
        before do
          fill_in('Add a reply', with: "/clone #{target_project.full_path}\n\n/label ~#{bug.title} ~#{wontfix.title}\n\n/milestone %\"#{milestone.title}\"")
          click_button 'Comment'
        end

        it_behaves_like 'applies the commands to issues in both projects, target and source'
      end
    end

    context 'when editing comments' do
      let(:target_project) { create(:project, :public) }

      before do
        target_project.add_maintainer(user)

        sign_in(user)
        visit project_issue_path(project, issue)
        wait_for_all_requests
      end

      it 'clones the issue after quickcommand note was updated' do
        # misspelled quick action
        fill_in('Add a reply', with: "test note.\n/cloe #{target_project.full_path}")
        click_button 'Comment'

        expect(issue.reload).not_to be_closed

        within('li.note', text: "/cloe #{target_project.full_path}") do
          click_button 'Edit comment'
          fill_in('Edit comment', with: "test note.\n/clone #{target_project.full_path}")
          click_button 'Save comment'
        end

        expect(page).to have_content 'test note.'
        expect(issue.reload).to be_open

        visit project_issue_path(target_project, issue)
        wait_for_all_requests

        expect(page).to have_content issue.title
      end

      it 'deletes the note if it was updated to just contain a command' do
        # missspelled quick action
        fill_in('Add a reply', with: "test note.\n/cloe #{target_project.full_path}")
        click_button 'Comment'

        expect(page).not_to have_content 'Commands applied'

        within('li.note', text: "/cloe #{target_project.full_path}") do
          click_button 'Edit comment'
          fill_in('Edit comment', with: "/clone #{target_project.full_path}")
          click_button 'Save comment'
        end

        expect(page).not_to have_content "/clone #{target_project.full_path}"
        expect(issue.reload).to be_open

        visit project_issue_path(target_project, issue)
        wait_for_all_requests

        expect(page).to have_content issue.title
      end
    end
  end
end
