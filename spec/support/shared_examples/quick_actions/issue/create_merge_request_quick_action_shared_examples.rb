# frozen_string_literal: true

RSpec.shared_examples 'create_merge_request quick action' do
  context 'create a merge request starting from an issue' do
    def expect_mr_quickaction(success, branch_name = nil)
      command_message = if branch_name
                          "Created branch '#{branch_name}' and a merge request to resolve this issue"
                        else
                          "Created a branch and a merge request to resolve this issue"
                        end

      expect(page).to have_content command_message

      if success
        expect(page).to have_content 'created merge request'
      else
        expect(page).not_to have_content 'created merge request'
      end
    end

    it "doesn't create a merge request when the branch name is invalid" do
      branch_name = 'invalid branch name'
      fill_in('Add a reply', with: "/create_merge_request #{branch_name}")
      click_button 'Comment'

      expect_mr_quickaction(false, branch_name)
    end

    it "doesn't create a merge request when a branch with that name already exists" do
      branch_name = 'feature'
      fill_in('Add a reply', with: "/create_merge_request #{branch_name}")
      click_button 'Comment'

      expect_mr_quickaction(false, branch_name)
    end

    it 'creates a new merge request using issue iid and title as branch name when the branch name is empty' do
      fill_in('Add a reply', with: '/create_merge_request')
      click_button 'Comment'

      expect_mr_quickaction(true)

      created_mr = project.merge_requests.last
      expect(created_mr.source_branch).to eq(issue.to_branch_name)

      visit project_merge_request_path(project, created_mr)
      expect(page).to have_content %(Draft: Resolve "#{issue.title}")
    end

    it 'creates a merge request using the given branch name' do
      branch_name = '1-feature'
      fill_in('Add a reply', with: "/create_merge_request #{branch_name}")
      click_button 'Comment'

      expect_mr_quickaction(true, branch_name)

      created_mr = project.merge_requests.last
      expect(created_mr.source_branch).to eq(branch_name)

      visit project_merge_request_path(project, created_mr)
      expect(page).to have_content %(Draft: Resolve "#{issue.title}")
    end
  end
end
