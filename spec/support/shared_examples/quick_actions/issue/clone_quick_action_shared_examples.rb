# frozen_string_literal: true

RSpec.shared_examples 'clone quick action' do
  context 'clone the issue to another project' do
    let(:target_project) { create(:project, :public) }

    context 'when no target is given' do
      it 'clones the issue in the current project' do
        add_note("/clone")

        expect(page).to have_content "Cloned this issue to #{project.full_path}."
        expect(issue.reload).to be_open

        visit project_issue_path(project, issue)

        expect(page).to have_content 'Issues 2'
      end
    end

    context 'when the project is valid' do
      before do
        target_project.add_maintainer(user)
      end

      it 'clones the issue' do
        add_note("/clone #{target_project.full_path}")

        expect(page).to have_content "Cloned this issue to #{target_project.full_path}."
        expect(issue.reload).to be_open

        visit project_issue_path(target_project, issue)

        expect(page).to have_content 'Issues 1'
      end

      context 'when cloning with notes', :aggregate_failures do
        it 'clones the issue with all notes' do
          add_note("Some random note")
          add_note("Another note")

          add_note("/clone --with_notes #{target_project.full_path}")

          expect(page).to have_content "Cloned this issue to #{target_project.full_path}."
          expect(issue.reload).to be_open

          visit project_issue_path(target_project, issue)

          expect(page).to have_content 'Issues 1'
          expect(page).to have_content 'Some random note'
          expect(page).to have_content 'Another note'
        end

        it 'returns an error if the params are malformed' do
          # Note that this is missing one `-`
          add_note("/clone -with_notes #{target_project.full_path}")

          expect(page).to have_content 'Failed to clone this issue: wrong parameters.'
          expect(issue.reload).to be_open
        end
      end
    end

    context 'when the project is valid but the user not authorized' do
      let(:project_unauthorized) { create(:project, :public) }

      it 'does not clone the issue' do
        add_note("/clone #{project_unauthorized.full_path}")

        expect(page).to have_content "Cloned this issue to #{project_unauthorized.full_path}."
        expect(issue.reload).to be_open

        visit project_issue_path(target_project, issue)

        expect(page).not_to have_content 'Issues 1'
      end
    end

    context 'when the project is invalid' do
      it 'does not clone the issue' do
        add_note("/clone not/valid")

        expect(page).to have_content "Failed to clone this issue because target project doesn't exist."
        expect(issue.reload).to be_open
      end
    end

    context 'when the user issues multiple commands' do
      let(:milestone) { create(:milestone, title: '1.0', project: project) }
      let(:bug)      { create(:label, project: project, title: 'bug') }
      let(:wontfix)  { create(:label, project: project, title: 'wontfix') }

      let!(:target_milestone) { create(:milestone, title: '1.0', project: target_project) }

      before do
        target_project.add_maintainer(user)
      end

      shared_examples 'applies the commands to issues in both projects, target and source' do
        it "applies quick actions" do
          expect(page).to have_content "Cloned this issue to #{target_project.full_path}."
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
          add_note("/label ~#{bug.title} ~#{wontfix.title}\n\n/milestone %\"#{milestone.title}\"\n\n/clone #{target_project.full_path}")
        end

        it_behaves_like 'applies the commands to issues in both projects, target and source'
      end

      context 'applies multiple commands with clone command in the begining' do
        before do
          add_note("/clone #{target_project.full_path}\n\n/label ~#{bug.title} ~#{wontfix.title}\n\n/milestone %\"#{milestone.title}\"")
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
        add_note("test note.\n/cloe #{target_project.full_path}")

        expect(issue.reload).not_to be_closed

        edit_note("/cloe #{target_project.full_path}", "test note.\n/clone #{target_project.full_path}")

        expect(page).to have_content 'test note.'
        expect(issue.reload).to be_open

        visit project_issue_path(target_project, issue)
        wait_for_all_requests

        expect(page).to have_content 'Issues 1'
      end

      it 'deletes the note if it was updated to just contain a command' do
        # missspelled quick action
        add_note("test note.\n/cloe #{target_project.full_path}")

        expect(page).not_to have_content 'Commands applied'

        edit_note("/cloe #{target_project.full_path}", "/clone #{target_project.full_path}")

        expect(page).not_to have_content "/clone #{target_project.full_path}"
        expect(issue.reload).to be_open

        visit project_issue_path(target_project, issue)
        wait_for_all_requests

        expect(page).to have_content 'Issues 1'
      end
    end
  end
end
