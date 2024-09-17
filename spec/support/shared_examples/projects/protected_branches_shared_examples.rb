# frozen_string_literal: true

RSpec.shared_examples 'setting project protected branches' do
  describe "explicit protected branches" do
    it "allows creating explicit protected branches" do
      visit project_protected_branches_path(project)

      show_add_form
      set_defaults
      set_protected_branch_name('some->branch')
      click_on "Protect"

      within(".protected-branches-list") { expect(page).to have_content('some->branch') }
      expect(ProtectedBranch.count).to eq(1)
      expect(ProtectedBranch.last.name).to eq('some->branch')
    end

    it "shows success alert once protected branch is created" do
      visit project_protected_branches_path(project)

      show_add_form
      set_defaults
      set_protected_branch_name('some->branch')
      click_on "Protect"
      wait_for_requests
      expect(page).to have_content(success_message)
    end

    it "displays the last commit on the matching branch if it exists" do
      commit = create(:commit, project: project)
      project.repository.add_branch(admin, 'some-branch', commit.id)

      visit project_protected_branches_path(project)

      show_add_form
      set_defaults
      set_protected_branch_name('some-branch')
      click_on "Protect"

      within(".protected-branches-list") do
        expect(page).not_to have_content("matching")
        expect(page).not_to have_content("was deleted")
      end
    end

    it "displays an error message if the named branch does not exist" do
      visit project_protected_branches_path(project)

      show_add_form
      set_defaults
      set_protected_branch_name('some-unexisting-branch')
      click_on "Protect"

      within(".protected-branches-list") { expect(page).to have_content('Branch does not exist') }
    end
  end

  describe "wildcard protected branches" do
    it "allows creating protected branches with a wildcard" do
      visit project_protected_branches_path(project)

      show_add_form
      set_defaults
      set_protected_branch_name('*-stable')
      click_on "Protect"

      within(".protected-branches-list") { expect(page).to have_content('*-stable') }
      expect(ProtectedBranch.count).to eq(1)
      expect(ProtectedBranch.last.name).to eq('*-stable')
    end

    it "displays the number of matching branches",
      quarantine: 'https://gitlab.com/gitlab-org/quality/engineering-productivity/flaky-tests/-/issues/3459' do
      project.repository.add_branch(admin, 'production-stable', 'master')
      project.repository.add_branch(admin, 'staging-stable', 'master')

      visit project_protected_branches_path(project)

      show_add_form
      set_defaults
      set_protected_branch_name('*-stable')
      click_on "Protect"

      within(".protected-branches-list") do
        expect(page).to have_content("2 matching branches")
      end
    end

    it "displays all the branches matching the wildcard" do
      project.repository.add_branch(admin, 'production-stable', 'master')
      project.repository.add_branch(admin, 'staging-stable', 'master')
      project.repository.add_branch(admin, 'development', 'master')

      visit project_protected_branches_path(project)

      show_add_form
      set_protected_branch_name('*-stable')
      set_defaults
      click_on "Protect"

      visit project_protected_branches_path(project)
      click_on "2 matching branches"

      within(".protected-branches-list") do
        expect(page).to have_content("production-stable")
        expect(page).to have_content("staging-stable")
        expect(page).not_to have_content("development")
      end
    end
  end
end
