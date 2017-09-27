require 'spec_helper'

describe SystemCheck::BaseCheck do
  context 'helpers on instance level' do
    it 'responds to SystemCheck::Helpers methods' do
      expect(subject).to respond_to :fix_and_rerun, :for_more_information, :see_installation_guide_section,
        :finished_checking, :start_checking, :try_fixing_it, :sanitized_message, :should_sanitize?, :omnibus_gitlab?,
        :sudo_gitlab
    end

    it 'responds to Gitlab::TaskHelpers methods' do
      expect(subject).to respond_to :ask_to_continue, :os_name, :prompt, :run_and_match, :run_command,
        :run_command!, :uid_for, :gid_for, :gitlab_user, :gitlab_user?, :warn_user_is_not_gitlab, :all_repos,
        :repository_storage_paths_args, :user_home, :checkout_or_clone_version, :clone_repo, :checkout_version
    end
  end
end
