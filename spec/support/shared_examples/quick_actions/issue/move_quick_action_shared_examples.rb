# frozen_string_literal: true

shared_examples 'move quick action' do
  context 'move the issue to another project' do
    let(:target_project) { create(:project, :public) }

    context 'when the project is valid' do
      before do
        target_project.add_maintainer(user)
      end

      it 'moves the issue' do
        add_note("/move #{target_project.full_path}")

        expect(page).to have_content "Moved this issue to #{target_project.full_path}."
        expect(issue.reload).to be_closed

        visit project_issue_path(target_project, issue)

        expect(page).to have_content 'Issues 1'
      end
    end

    context 'when the project is valid but the user not authorized' do
      let(:project_unauthorized) { create(:project, :public) }

      it 'does not move the issue' do
        add_note("/move #{project_unauthorized.full_path}")

        wait_for_requests

        expect(page).to have_content "Moved this issue to #{project_unauthorized.full_path}."
        expect(issue.reload).to be_open
      end
    end

    context 'when the project is invalid' do
      it 'does not move the issue' do
        add_note("/move not/valid")

        wait_for_requests

        expect(page).to have_content "Move this issue failed because target project doesn't exists"
        expect(issue.reload).to be_open
      end
    end

    context 'when the user issues multiple commands' do
      let(:milestone) { create(:milestone, title: '1.0', project: project) }
      let(:bug)      { create(:label, project: project, title: 'bug') }
      let(:wontfix)  { create(:label, project: project, title: 'wontfix') }

      before do
        target_project.add_maintainer(user)
      end

      shared_examples 'applies the commands to issues in both projects, target and source' do
        it "applies quick actions" do
          expect(page).to have_content "Moved this issue to #{target_project.full_path}."
          expect(issue.reload).to be_closed

          visit project_issue_path(target_project, issue)

          expect(page).to have_content 'bug'
          expect(page).to have_content 'wontfix'
          expect(page).to have_content '1.0'

          visit project_issue_path(project, issue)
          expect(page).to have_content 'Closed'
          expect(page).to have_content 'bug'
          expect(page).to have_content 'wontfix'
          expect(page).to have_content '1.0'
        end
      end

      context 'applies multiple commands with move command in the end' do
        before do
          add_note("/label ~#{bug.title} ~#{wontfix.title}\n\n/milestone %\"#{milestone.title}\"\n\n/move #{target_project.full_path}")
        end

        it_behaves_like 'applies the commands to issues in both projects, target and source'
      end

      context 'applies multiple commands with move command in the begining' do
        before do
          add_note("/move #{target_project.full_path}\n\n/label ~#{bug.title} ~#{wontfix.title}\n\n/milestone %\"#{milestone.title}\"")
        end

        it_behaves_like 'applies the commands to issues in both projects, target and source'
      end
    end
  end
end
