# frozen_string_literal: true

shared_examples 'create_merge_request quick action' do
  context 'create a merge request starting from an issue' do
    def expect_mr_quickaction(success)
      expect(page).to have_content 'Commands applied'

      if success
        expect(page).to have_content 'created merge request'
      else
        expect(page).not_to have_content 'created merge request'
      end
    end

    it "doesn't create a merge request when the branch name is invalid" do
      add_note("/create_merge_request invalid branch name")

      wait_for_requests

      expect_mr_quickaction(false)
    end

    it "doesn't create a merge request when a branch with that name already exists" do
      add_note("/create_merge_request feature")

      wait_for_requests

      expect_mr_quickaction(false)
    end

    it 'creates a new merge request using issue iid and title as branch name when the branch name is empty' do
      add_note("/create_merge_request")

      wait_for_requests

      expect_mr_quickaction(true)

      created_mr = project.merge_requests.last
      expect(created_mr.source_branch).to eq(issue.to_branch_name)

      visit project_merge_request_path(project, created_mr)
      expect(page).to have_content %{WIP: Resolve "#{issue.title}"}
    end

    it 'creates a merge request using the given branch name' do
      branch_name = '1-feature'
      add_note("/create_merge_request #{branch_name}")

      expect_mr_quickaction(true)

      created_mr = project.merge_requests.last
      expect(created_mr.source_branch).to eq(branch_name)

      visit project_merge_request_path(project, created_mr)
      expect(page).to have_content %{WIP: Resolve "#{issue.title}"}
    end
  end
end
