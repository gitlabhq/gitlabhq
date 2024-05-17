# frozen_string_literal: true

RSpec.shared_examples "protected branches > access control > CE" do
  let(:no_one) { ProtectedRef::AccessLevel.humanize(::Gitlab::Access::NO_ACCESS) }
  let(:edit_form) { '.js-protected-branch-edit-form' }

  ProtectedRef::AccessLevel.human_access_levels.each do |(access_type_id, access_type_name)|
    it "allows creating protected branches that #{access_type_name} can push to",
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/462438' do
      visit project_protected_branches_path(project)

      show_add_form
      set_protected_branch_name('master')
      set_allowed_to('merge', no_one)
      set_allowed_to('push', access_type_name)
      click_on_protect

      expect(ProtectedBranch.count).to eq(1)
      expect(ProtectedBranch.last.push_access_levels.map(&:access_level)).to eq([access_type_id])
    end

    it "allows creating protected branches that #{access_type_name} can merge to" do
      visit project_protected_branches_path(project)

      show_add_form
      set_protected_branch_name('master')
      set_allowed_to('merge', access_type_name)
      set_allowed_to('push', no_one)
      click_on_protect

      expect(ProtectedBranch.count).to eq(1)
      expect(ProtectedBranch.last.merge_access_levels.map(&:access_level)).to eq([access_type_id])
    end

    it "allows updating protected branches so that #{access_type_name} can push to them",
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/462438' do
      visit project_protected_branches_path(project)

      show_add_form
      set_protected_branch_name('master')
      set_allowed_to('merge', no_one)
      set_allowed_to('push', no_one)
      click_on_protect

      expect(ProtectedBranch.count).to eq(1)

      set_allowed_to('push', access_type_name, form: edit_form)
      wait_for_requests

      expect(ProtectedBranch.last.push_access_levels.map(&:access_level)).to include(access_type_id)
    end

    it "allows updating protected branches so that #{access_type_name} can merge to them",
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/462438' do
      visit project_protected_branches_path(project)

      show_add_form
      set_protected_branch_name('master')
      set_allowed_to('merge', no_one)
      set_allowed_to('push', no_one)
      click_on_protect

      expect(ProtectedBranch.count).to eq(1)

      set_allowed_to('merge', access_type_name, form: edit_form)
      wait_for_requests

      expect(ProtectedBranch.last.merge_access_levels.map(&:access_level)).to include(access_type_id)
    end
  end
end
