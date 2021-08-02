# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitAccess do
  include TermsHelper
  include GitHelpers
  include AdminModeHelper

  let(:user) { create(:user) }

  let(:actor) { user }
  let(:project) { create(:project, :repository) }
  let(:repository_path) { "#{project.full_path}.git" }
  let(:protocol) { 'ssh' }
  let(:authentication_abilities) { %i[read_project download_code push_code] }
  let(:redirected_path) { nil }
  let(:auth_result_type) { nil }
  let(:changes) { Gitlab::GitAccess::ANY }
  let(:push_access_check) { access.check('git-receive-pack', changes) }
  let(:pull_access_check) { access.check('git-upload-pack', changes) }

  let(:access_class) do
    Class.new(described_class) do
      def push_ability
        :push_code
      end

      def download_ability
        :download_code
      end
    end
  end

  describe '#check with single protocols allowed' do
    def disable_protocol(protocol)
      allow(Gitlab::ProtocolAccess).to receive(:allowed?).with(protocol).and_return(false)
    end

    context 'ssh disabled' do
      before do
        disable_protocol('ssh')
      end

      it 'blocks ssh git push and pull' do
        aggregate_failures do
          expect { push_access_check }.to raise_forbidden('Git access over SSH is not allowed')
          expect { pull_access_check }.to raise_forbidden('Git access over SSH is not allowed')
        end
      end
    end

    context 'http disabled' do
      let(:protocol) { 'http' }

      before do
        disable_protocol('http')
        project.add_maintainer(user)
      end

      it 'blocks http push and pull' do
        aggregate_failures do
          expect { push_access_check }.to raise_forbidden('Git access over HTTP is not allowed')
          expect { pull_access_check }.to raise_forbidden('Git access over HTTP is not allowed')
        end
      end

      context 'when request is made from CI' do
        let(:auth_result_type) { :build }

        it "doesn't block http pull" do
          aggregate_failures do
            expect { pull_access_check }.not_to raise_error
          end
        end

        context 'when legacy CI credentials are used' do
          let(:auth_result_type) { :ci }

          it "doesn't block http pull" do
            aggregate_failures do
              expect { pull_access_check }.not_to raise_error
            end
          end
        end
      end
    end
  end

  describe '#check_project_accessibility!' do
    context 'when the project exists' do
      context 'when actor exists' do
        context 'when actor is a DeployKey' do
          let(:deploy_key) { create(:deploy_key, user: user) }
          let(:actor) { deploy_key }

          context 'when the DeployKey has access to the project' do
            before do
              deploy_key.deploy_keys_projects.create(project: project, can_push: true)
            end

            it 'allows push and pull access' do
              aggregate_failures do
                expect { push_access_check }.not_to raise_error
                expect { pull_access_check }.not_to raise_error
              end
            end
          end

          context 'when the Deploykey does not have access to the project' do
            it 'blocks push and pull with "not found"' do
              aggregate_failures do
                expect { push_access_check }.to raise_not_found
                expect { pull_access_check }.to raise_not_found
              end
            end
          end
        end

        context 'when actor is a User' do
          context 'when the User can read the project' do
            before do
              project.add_maintainer(user)
            end

            it 'allows push and pull access' do
              aggregate_failures do
                expect { pull_access_check }.not_to raise_error
                expect { push_access_check }.not_to raise_error
              end
            end
          end

          context 'when the User cannot read the project' do
            it 'blocks push and pull with "not found"' do
              aggregate_failures do
                expect { push_access_check }.to raise_not_found
                expect { pull_access_check }.to raise_not_found
              end
            end
          end
        end

        # For backwards compatibility
        context 'when actor is :ci' do
          let(:actor) { :ci }
          let(:authentication_abilities) { build_authentication_abilities }

          it 'allows pull access' do
            expect { pull_access_check }.not_to raise_error
          end

          it 'does not block pushes with "not found"' do
            expect { push_access_check }.to raise_forbidden(described_class::ERROR_MESSAGES[:auth_upload])
          end
        end

        context 'when actor is DeployToken' do
          let(:actor) { create(:deploy_token, projects: [project]) }

          context 'when DeployToken is active and belongs to project' do
            it 'allows pull access' do
              expect { pull_access_check }.not_to raise_error
            end

            it 'blocks the push' do
              expect { push_access_check }.to raise_forbidden(described_class::ERROR_MESSAGES[:upload])
            end
          end

          context 'when DeployToken does not belong to project' do
            let(:another_project) { create(:project) }
            let(:actor) { create(:deploy_token, projects: [another_project]) }

            it 'blocks pull access' do
              expect { pull_access_check }.to raise_not_found
            end

            it 'blocks the push' do
              expect { push_access_check }.to raise_not_found
            end
          end
        end
      end

      context 'when actor is nil' do
        let(:actor) { nil }

        context 'when guests can read the project' do
          let(:project) { create(:project, :repository, :public) }

          it 'allows pull access' do
            expect { pull_access_check }.not_to raise_error
          end

          it 'does not block pushes with "not found"' do
            expect { push_access_check }.to raise_forbidden(described_class::ERROR_MESSAGES[:upload])
          end
        end

        context 'when guests cannot read the project' do
          it 'blocks pulls with "not found"' do
            expect { pull_access_check }.to raise_not_found
          end

          it 'blocks pushes with "not found"' do
            expect { push_access_check }.to raise_not_found
          end
        end
      end
    end

    context 'when the project does not exist' do
      let(:project) { nil }
      let(:repository_path) { "#{user.namespace.path}/new-project.git" }

      it 'blocks push and pull with "not found"' do
        aggregate_failures do
          expect { pull_access_check }.to raise_not_found
          expect { push_access_check }.to raise_not_found
        end
      end
    end
  end

  shared_examples '#check with a key that is not valid' do
    before do
      project.add_maintainer(user)
    end

    context 'key is too small' do
      before do
        stub_application_setting(rsa_key_restriction: 4096)
      end

      it 'does not allow keys which are too small', :aggregate_failures do
        expect(actor).not_to be_valid
        expect { pull_access_check }.to raise_forbidden('Your SSH key must be at least 4096 bits.')
        expect { push_access_check }.to raise_forbidden('Your SSH key must be at least 4096 bits.')
      end
    end

    context 'key type is not allowed' do
      before do
        stub_application_setting(rsa_key_restriction: ApplicationSetting::FORBIDDEN_KEY_VALUE)
      end

      it 'does not allow keys which are too small', :aggregate_failures do
        expect(actor).not_to be_valid
        expect { pull_access_check }.to raise_forbidden(/Your SSH key type is forbidden/)
        expect { push_access_check }.to raise_forbidden(/Your SSH key type is forbidden/)
      end
    end
  end

  it_behaves_like '#check with a key that is not valid' do
    let(:actor) { build(:rsa_key_2048, user: user) }
  end

  it_behaves_like '#check with a key that is not valid' do
    let(:actor) { build(:rsa_deploy_key_2048, user: user) }
  end

  shared_examples 'check_project_moved' do
    it 'enqueues a redirected message for pushing' do
      push_access_check

      expect(Gitlab::Checks::ContainerMoved.fetch_message(user, project.repository)).not_to be_nil
    end

    it 'allows push and pull access' do
      aggregate_failures do
        expect { push_access_check }.not_to raise_error
        expect { pull_access_check }.not_to raise_error
      end
    end
  end

  describe '#add_project_moved_message!', :clean_gitlab_redis_shared_state do
    before do
      project.add_maintainer(user)
    end

    context 'when a redirect was not followed to find the project' do
      it 'allows push and pull access' do
        aggregate_failures do
          expect { push_access_check }.not_to raise_error
          expect { pull_access_check }.not_to raise_error
        end
      end
    end

    context 'with a redirect and ssh protocol' do
      let(:redirected_path) { 'some/other-path' }

      it_behaves_like 'check_project_moved'
    end

    context 'with a redirect and http protocol' do
      let(:redirected_path) { 'some/other-path' }
      let(:protocol) { 'http' }

      it_behaves_like 'check_project_moved'
    end
  end

  describe '#check_authentication_abilities!' do
    before do
      project.add_maintainer(user)
    end

    context 'when download' do
      let(:authentication_abilities) { [] }

      it 'raises unauthorized with download error' do
        expect { pull_access_check }.to raise_forbidden(described_class::ERROR_MESSAGES[:auth_download])
      end

      context 'when authentication abilities include download code' do
        let(:authentication_abilities) { [:download_code] }

        it 'does not raise any errors' do
          expect { pull_access_check }.not_to raise_error
        end
      end

      context 'when authentication abilities include build download code' do
        let(:authentication_abilities) { [:build_download_code] }

        it 'does not raise any errors' do
          expect { pull_access_check }.not_to raise_error
        end
      end
    end

    context 'when upload' do
      let(:authentication_abilities) { [] }

      it 'raises unauthorized with push error' do
        expect { push_access_check }.to raise_forbidden(described_class::ERROR_MESSAGES[:auth_upload])
      end

      context 'when authentication abilities include push code' do
        let(:authentication_abilities) { [:push_code] }

        it 'does not raise any errors' do
          expect { push_access_check }.not_to raise_error
        end
      end
    end
  end

  describe '#check_command_disabled!' do
    before do
      project.add_maintainer(user)
    end

    context 'over http' do
      let(:protocol) { 'http' }

      context 'when the git-upload-pack command is disabled in config' do
        before do
          allow(Gitlab.config.gitlab_shell).to receive(:upload_pack).and_return(false)
        end

        context 'when calling git-upload-pack' do
          it { expect { pull_access_check }.to raise_forbidden('Pulling over HTTP is not allowed.') }
        end

        context 'when calling git-receive-pack' do
          it { expect { push_access_check }.not_to raise_error }
        end
      end

      context 'when the git-receive-pack command is disabled in config' do
        before do
          allow(Gitlab.config.gitlab_shell).to receive(:receive_pack).and_return(false)
        end

        context 'when calling git-receive-pack' do
          it { expect { push_access_check }.to raise_forbidden('Pushing over HTTP is not allowed.') }
        end

        context 'when calling git-upload-pack' do
          it { expect { pull_access_check }.not_to raise_error }
        end
      end
    end
  end

  describe '#check_db_accessibility!' do
    context 'when in a read-only GitLab instance' do
      before do
        create(:protected_branch, name: 'feature', project: project)
        allow(Gitlab::Database).to receive(:read_only?) { true }
      end

      it { expect { push_access_check }.to raise_forbidden(described_class::ERROR_MESSAGES[:cannot_push_to_read_only]) }
    end
  end

  describe '#check_download_access!' do
    it 'allows maintainers to pull' do
      project.add_maintainer(user)

      expect { pull_access_check }.not_to raise_error
    end

    it 'disallows guests to pull' do
      project.add_guest(user)

      expect { pull_access_check }.to raise_forbidden(described_class::ERROR_MESSAGES[:download])
    end

    it 'disallows blocked users to pull' do
      project.add_maintainer(user)
      user.block

      expect { pull_access_check }.to raise_forbidden('Your account has been blocked.')
    end

    it 'disallows users that are blocked pending approval to pull' do
      project.add_maintainer(user)
      user.block_pending_approval

      expect { pull_access_check }.to raise_forbidden('Your account is pending approval from your administrator and hence blocked.')
    end

    it 'disallows deactivated users to pull' do
      project.add_maintainer(user)
      user.deactivate!

      expect { pull_access_check }.to raise_forbidden("Your account has been deactivated by your administrator. Please log back in from a web browser to reactivate your account at #{Gitlab.config.gitlab.url}")
    end

    it 'disallows users with expired password to pull' do
      project.add_maintainer(user)
      user.update!(password_expires_at: 2.minutes.ago, password_automatically_set: true)

      expect { pull_access_check }.to raise_forbidden("Your password expired. Please access GitLab from a web browser to update your password.")
    end

    it 'allows ldap users with expired password to pull' do
      project.add_maintainer(user)
      user.update!(password_expires_at: 2.minutes.ago)
      allow(user).to receive(:ldap_user?).and_return(true)

      expect { pull_access_check }.not_to raise_error
    end

    context 'when the project repository does not exist' do
      before do
        project.add_guest(user)
        allow(project.repository).to receive(:exists?).and_return(false)
      end

      it 'returns not found' do
        expect { pull_access_check }.to raise_error(Gitlab::GitAccess::NotFoundError, 'A repository for this project does not exist yet.')
      end
    end

    describe 'without access to project' do
      context 'pull code' do
        it { expect { pull_access_check }.to raise_not_found }
      end

      context 'when project is public' do
        let(:public_project) { create(:project, :public, :repository) }
        let(:repository_path) { "#{public_project.full_path}.git" }
        let(:access) { access_class.new(nil, public_project, 'web', authentication_abilities: [:download_code], repository_path: repository_path) }

        context 'when repository is enabled' do
          it 'give access to download code' do
            expect { pull_access_check }.not_to raise_error
          end
        end

        context 'when repository is disabled' do
          it 'does not give access to download code' do
            public_project.project_feature.update_attribute(:repository_access_level, ProjectFeature::DISABLED)

            expect { pull_access_check }.to raise_forbidden(described_class::ERROR_MESSAGES[:download])
          end
        end
      end
    end

    describe 'deploy key permissions' do
      let(:key) { create(:deploy_key, user: user) }
      let(:actor) { key }

      context 'pull code' do
        context 'when project is public' do
          let(:project) { create(:project, :public, :repository, *options) }

          context 'when deploy key exists in the project' do
            before do
              key.projects << project
            end

            context 'when the repository is public' do
              let(:options) { %i[repository_enabled] }

              it { expect { pull_access_check }.not_to raise_error }
            end

            context 'when the repository is private' do
              let(:options) { %i[repository_private] }

              it { expect { pull_access_check }.not_to raise_error }
            end

            context 'when the repository is disabled' do
              let(:options) { %i[repository_disabled] }

              it { expect { pull_access_check }.to raise_error('You are not allowed to download code from this project.') }
            end
          end

          context 'when deploy key does not exist in the project' do
            context 'when the repository is public' do
              let(:options) { %i[repository_enabled] }

              it { expect { pull_access_check }.not_to raise_error }
            end

            context 'when the repository is private' do
              let(:options) { %i[repository_private] }

              it { expect { pull_access_check }.to raise_error('You are not allowed to download code from this project.') }
            end

            context 'when the repository is disabled' do
              let(:options) { %i[repository_disabled] }

              it { expect { pull_access_check }.to raise_error('You are not allowed to download code from this project.') }
            end
          end
        end

        context 'when project is internal' do
          let(:project) { create(:project, :internal, :repository, *options) }

          context 'when deploy key exists in the project' do
            before do
              key.projects << project
            end

            context 'when the repository is public' do
              let(:options) { %i[repository_enabled] }

              it { expect { pull_access_check }.not_to raise_error }
            end

            context 'when the repository is private' do
              let(:options) { %i[repository_private] }

              it { expect { pull_access_check }.not_to raise_error }
            end

            context 'when the repository is disabled' do
              let(:options) { %i[repository_disabled] }

              it { expect { pull_access_check }.to raise_error('You are not allowed to download code from this project.') }
            end
          end

          context 'when deploy key does not exist in the project' do
            context 'when the repository is public' do
              let(:options) { %i[repository_enabled] }

              it { expect { pull_access_check }.to raise_error("The project you were looking for could not be found or you don't have permission to view it.") }
            end

            context 'when the repository is private' do
              let(:options) { %i[repository_private] }

              it { expect { pull_access_check }.to raise_error("The project you were looking for could not be found or you don't have permission to view it.") }
            end

            context 'when the repository is disabled' do
              let(:options) { %i[repository_disabled] }

              it { expect { pull_access_check }.to raise_error("The project you were looking for could not be found or you don't have permission to view it.") }
            end
          end
        end

        context 'when project is private' do
          let(:project) { create(:project, :private, :repository, *options) }

          context 'when deploy key exists in the project' do
            before do
              key.projects << project
            end

            context 'when the repository is private' do
              let(:options) { %i[repository_private] }

              it { expect { pull_access_check }.not_to raise_error }
            end

            context 'when the repository is disabled' do
              let(:options) { %i[repository_disabled] }

              it { expect { pull_access_check }.to raise_error('You are not allowed to download code from this project.') }
            end
          end

          context 'when deploy key does not exist in the project' do
            context 'when the repository is private' do
              let(:options) { %i[repository_private] }

              it { expect { pull_access_check }.to raise_error("The project you were looking for could not be found or you don't have permission to view it.") }
            end

            context 'when the repository is disabled' do
              let(:options) { %i[repository_disabled] }

              it { expect { pull_access_check }.to raise_error("The project you were looking for could not be found or you don't have permission to view it.") }
            end
          end
        end
      end
    end

    describe 'deploy token permissions' do
      let(:deploy_token) { create(:deploy_token) }
      let(:actor) { deploy_token }

      context 'pull code' do
        context 'when project is authorized' do
          before do
            deploy_token.projects << project
          end

          it { expect { pull_access_check }.not_to raise_error }
        end

        context 'when unauthorized' do
          context 'from public project' do
            let(:project) { create(:project, :public, :repository) }

            it { expect { pull_access_check }.not_to raise_error }
          end

          context 'from internal project' do
            let(:project) { create(:project, :internal, :repository) }

            it { expect { pull_access_check }.to raise_not_found }
          end

          context 'from private project' do
            let(:project) { create(:project, :private, :repository) }

            it { expect { pull_access_check }.to raise_not_found }
          end
        end
      end
    end

    describe 'build authentication_abilities permissions' do
      let(:authentication_abilities) { build_authentication_abilities }

      describe 'owner' do
        let(:project) { create(:project, :repository, namespace: user.namespace) }

        context 'pull code' do
          it { expect { pull_access_check }.not_to raise_error }
        end
      end

      describe 'reporter user' do
        before do
          project.add_reporter(user)
        end

        context 'pull code' do
          it { expect { pull_access_check }.not_to raise_error }
        end
      end

      describe 'admin user' do
        let(:user) { create(:admin) }

        context 'when admin mode enabled', :enable_admin_mode do
          context 'when member of the project' do
            before do
              project.add_reporter(user)
            end

            context 'pull code' do
              it { expect { pull_access_check }.not_to raise_error }
            end
          end

          context 'when is not member of the project' do
            context 'pull code' do
              it { expect { pull_access_check }.to raise_forbidden(described_class::ERROR_MESSAGES[:download]) }
            end
          end
        end

        context 'when admin mode disabled' do
          context 'when member of the project' do
            before do
              project.add_reporter(user)
            end

            context 'pull code' do
              it { expect { pull_access_check }.not_to raise_error }
            end
          end

          context 'when is not member of the project' do
            context 'pull code' do
              it { expect { pull_access_check }.to raise_not_found }
            end
          end
        end
      end

      describe 'generic CI (build without a user)' do
        let(:actor) { :ci }

        context 'pull code' do
          it { expect { pull_access_check }.not_to raise_error }
        end
      end
    end
  end

  describe 'check LFS integrity' do
    let(:changes) { ['6f6d7e7ed 570e7b2ab refs/heads/master', '6f6d7e7ed 570e7b2ab refs/heads/feature'] }

    before do
      project.add_developer(user)
    end

    context 'when LFS is not enabled' do
      it 'does not run LFSIntegrity check' do
        allow(project).to receive(:lfs_enabled?).and_return(false)

        expect(Gitlab::Checks::LfsIntegrity).not_to receive(:new)

        push_access_check
      end
    end

    context 'when LFS is enabled' do
      it 'checks LFS integrity only for first change' do
        allow(project).to receive(:lfs_enabled?).and_return(true)

        expect_next_instance_of(Gitlab::Checks::LfsIntegrity) do |instance|
          expect(instance).to receive(:objects_missing?).once
        end

        push_access_check
      end
    end
  end

  describe '#check_push_access!' do
    let(:unprotected_branch) { 'unprotected_branch' }

    before do
      merge_into_protected_branch
    end

    let(:changes) do
      { any: Gitlab::GitAccess::ANY,
        push_new_branch: "#{Gitlab::Git::BLANK_SHA} 570e7b2ab refs/heads/wow",
        push_master: '6f6d7e7ed 570e7b2ab refs/heads/master',
        push_protected_branch: '6f6d7e7ed 570e7b2ab refs/heads/feature',
        push_remove_protected_branch: "570e7b2ab #{Gitlab::Git::BLANK_SHA} "\
                                      'refs/heads/feature',
        push_tag: '6f6d7e7ed 570e7b2ab refs/tags/v1.0.0',
        push_new_tag: "#{Gitlab::Git::BLANK_SHA} 570e7b2ab refs/tags/v7.8.9",
        push_all: ['6f6d7e7ed 570e7b2ab refs/heads/master', '6f6d7e7ed 570e7b2ab refs/heads/feature'],
        merge_into_protected_branch: "0b4bc9a #{merge_into_protected_branch} refs/heads/feature" }
    end

    def merge_into_protected_branch
      @protected_branch_merge_commit ||= begin
        project.repository.add_branch(user, unprotected_branch, 'feature')
        rugged = rugged_repo(project.repository)
        target_branch = rugged.rev_parse('feature')
        source_branch = project.repository.create_file(
          user,
          'filename',
          'This is the file content',
          message: 'This is a good commit message',
          branch_name: unprotected_branch)
        author = { email: "email@example.com", time: Time.now, name: "Example Git User" }

        merge_index = rugged.merge_commits(target_branch, source_branch)
        Rugged::Commit.create(rugged, author: author, committer: author, message: "commit message", parents: [target_branch, source_branch], tree: merge_index.write_tree(rugged))
      end
    end

    def self.run_permission_checks(permissions_matrix)
      permissions_matrix.each_pair do |role, matrix|
        # Run through the entire matrix for this role in one test to avoid
        # repeated setup.
        #
        # Expectations are given a custom failure message proc so that it's
        # easier to identify which check(s) failed.
        it "has the correct permissions for #{role}s" do
          if role == :admin_without_admin_mode
            skip("All admins are allowed to perform actions https://gitlab.com/gitlab-org/gitlab/-/issues/296509")
          end

          if [:admin_with_admin_mode, :admin_without_admin_mode].include?(role)
            user.update_attribute(:admin, true)
            enable_admin_mode!(user) if role == :admin_with_admin_mode
            project.add_guest(user)
          else
            project.add_role(user, role)
          end

          protected_branch.save

          aggregate_failures do
            matrix.each do |action, allowed|
              check = -> { push_changes(changes[action]) }

              if allowed
                expect(&check).not_to raise_error,
                  -> { "expected #{action} to be allowed" }
              else
                expect(&check).to raise_error(Gitlab::GitAccess::ForbiddenError),
                  -> { "expected #{action} to be disallowed" }
              end
            end
          end
        end
      end
    end

    permissions_matrix = {
      admin_with_admin_mode: {
        any: true,
        push_new_branch: true,
        push_master: true,
        push_protected_branch: true,
        push_remove_protected_branch: false,
        push_tag: true,
        push_new_tag: true,
        push_all: true,
        merge_into_protected_branch: true
      },

      admin_without_admin_mode: {
        any: false,
        push_new_branch: false,
        push_master: false,
        push_protected_branch: false,
        push_remove_protected_branch: false,
        push_tag: false,
        push_new_tag: false,
        push_all: false,
        merge_into_protected_branch: false
      },

      maintainer: {
        any: true,
        push_new_branch: true,
        push_master: true,
        push_protected_branch: true,
        push_remove_protected_branch: false,
        push_tag: true,
        push_new_tag: true,
        push_all: true,
        merge_into_protected_branch: true
      },

      developer: {
        any: true,
        push_new_branch: true,
        push_master: true,
        push_protected_branch: false,
        push_remove_protected_branch: false,
        push_tag: true,
        push_new_tag: true,
        push_all: false,
        merge_into_protected_branch: false
      },

      reporter: {
        any: false,
        push_new_branch: false,
        push_master: false,
        push_protected_branch: false,
        push_remove_protected_branch: false,
        push_tag: false,
        push_new_tag: false,
        push_all: false,
        merge_into_protected_branch: false
      },

      guest: {
        any: false,
        push_new_branch: false,
        push_master: false,
        push_protected_branch: false,
        push_remove_protected_branch: false,
        push_tag: false,
        push_new_tag: false,
        push_all: false,
        merge_into_protected_branch: false
      }
    }

    [%w(feature exact), ['feat*', 'wildcard']].each do |protected_branch_name, protected_branch_type|
      context do
        let(:protected_branch) { create(:protected_branch, :maintainers_can_push, name: protected_branch_name, project: project) }

        run_permission_checks(permissions_matrix)
      end

      context "when developers are allowed to push into the #{protected_branch_type} protected branch" do
        let(:protected_branch) { create(:protected_branch, :developers_can_push, name: protected_branch_name, project: project) }

        run_permission_checks(permissions_matrix.deep_merge(developer: { push_protected_branch: true, push_all: true, merge_into_protected_branch: true }))
      end

      context "developers are allowed to merge into the #{protected_branch_type} protected branch" do
        let(:protected_branch) { create(:protected_branch, :developers_can_merge, name: protected_branch_name, project: project) }

        context "when a merge request exists for the given source/target branch" do
          context "when the merge request is in progress" do
            before do
              create(:merge_request, source_project: project, source_branch: unprotected_branch, target_branch: 'feature',
                                     state: 'locked', in_progress_merge_commit_sha: merge_into_protected_branch)
            end

            run_permission_checks(permissions_matrix.deep_merge(developer: { merge_into_protected_branch: true }))
          end

          context "when the merge request is not in progress" do
            before do
              create(:merge_request, source_project: project, source_branch: unprotected_branch, target_branch: 'feature', in_progress_merge_commit_sha: nil)
            end

            run_permission_checks(permissions_matrix.deep_merge(developer: { merge_into_protected_branch: false }))
          end

          context "when a merge request does not exist for the given source/target branch" do
            run_permission_checks(permissions_matrix.deep_merge(developer: { merge_into_protected_branch: false }))
          end
        end
      end

      context "when developers are allowed to push and merge into the #{protected_branch_type} protected branch" do
        let(:protected_branch) { create(:protected_branch, :developers_can_merge, :developers_can_push, name: protected_branch_name, project: project) }

        run_permission_checks(permissions_matrix.deep_merge(developer: { push_protected_branch: true, push_all: true, merge_into_protected_branch: true }))
      end

      context "when no one is allowed to push to the #{protected_branch_name} protected branch" do
        let(:protected_branch) { build(:protected_branch, :no_one_can_push, name: protected_branch_name, project: project) }

        run_permission_checks(permissions_matrix.deep_merge(developer: { push_protected_branch: false, push_all: false, merge_into_protected_branch: false },
                                                            maintainer: { push_protected_branch: false, push_all: false, merge_into_protected_branch: false },
                                                            admin_with_admin_mode: { push_protected_branch: false, push_all: false, merge_into_protected_branch: false }))
      end
    end

    context 'when pushing to a project' do
      let(:project) { create(:project, :public, :repository) }
      let(:changes) { "#{Gitlab::Git::BLANK_SHA} 570e7b2ab refs/heads/wow" }

      before do
        project.add_developer(user)
      end

      it 'disallows users that are blocked pending approval to push' do
        user.block_pending_approval

        expect { push_access_check }.to raise_forbidden('Your account is pending approval from your administrator and hence blocked.')
      end

      it 'does not allow deactivated users to push' do
        user.deactivate!

        expect { push_access_check }.to raise_forbidden("Your account has been deactivated by your administrator. Please log back in from a web browser to reactivate your account at #{Gitlab.config.gitlab.url}")
      end

      it 'disallows users with expired password to push' do
        user.update!(password_expires_at: 2.minutes.ago, password_automatically_set: true)

        expect { push_access_check }.to raise_forbidden("Your password expired. Please access GitLab from a web browser to update your password.")
      end

      it 'allows ldap users with expired password to push' do
        user.update!(password_expires_at: 2.minutes.ago)
        allow(user).to receive(:ldap_user?).and_return(true)

        expect { push_access_check }.not_to raise_error
      end

      it 'disallows blocked ldap users with expired password to push' do
        user.block
        user.update!(password_expires_at: 2.minutes.ago)
        allow(user).to receive(:ldap_user?).and_return(true)

        expect { push_access_check }.to raise_forbidden("Your account has been blocked.")
      end

      it 'cleans up the files' do
        expect(project.repository).to receive(:clean_stale_repository_files).and_call_original
        expect { push_access_check }.not_to raise_error
      end

      it 'avoids N+1 queries', :request_store do
        # Run this once to establish a baseline. Cached queries should get
        # cached, so that when we introduce another change we shouldn't see
        # additional queries.
        access.check('git-receive-pack', changes)

        control_count = ActiveRecord::QueryRecorder.new do
          access.check('git-receive-pack', changes)
        end

        changes = ['6f6d7e7ed 570e7b2ab refs/heads/master', '6f6d7e7ed 570e7b2ab refs/heads/feature']

        # There is still an N+1 query with protected branches
        expect { access.check('git-receive-pack', changes) }.not_to exceed_query_limit(control_count).with_threshold(2)
      end

      it 'raises TimeoutError when #check_access! raises a timeout error' do
        message = "Push operation timed out\n\nTiming information for debugging purposes:\nRunning checks for ref: wow"

        expect_next_instance_of(Gitlab::Checks::SingleChangeAccess) do |check|
          expect(check).to receive(:validate!).and_raise(Gitlab::Checks::TimedLogger::TimeoutError)
        end

        expect { access.check('git-receive-pack', changes) }.to raise_error(described_class::TimeoutError, message)
      end
    end
  end

  describe 'build authentication abilities' do
    let(:authentication_abilities) { build_authentication_abilities }

    context 'when project is authorized' do
      before do
        project.add_reporter(user)
      end

      it { expect { push_access_check }.to raise_forbidden(described_class::ERROR_MESSAGES[:auth_upload]) }
    end

    context 'when unauthorized' do
      context 'to public project' do
        let(:project) { create(:project, :public, :repository) }

        it { expect { push_access_check }.to raise_forbidden(described_class::ERROR_MESSAGES[:auth_upload]) }
      end

      context 'to internal project' do
        let(:project) { create(:project, :internal, :repository) }

        it { expect { push_access_check }.to raise_forbidden(described_class::ERROR_MESSAGES[:auth_upload]) }
      end

      context 'to private project' do
        let(:project) { create(:project, :private, :repository) }

        it { expect { push_access_check }.to raise_forbidden(described_class::ERROR_MESSAGES[:auth_upload]) }
      end
    end
  end

  context 'when the repository is read-only' do
    let(:project) { create(:project, :repository, :read_only) }

    it 'denies push access' do
      project.add_maintainer(user)

      expect { push_access_check }.to raise_forbidden('The repository is temporarily read-only. Please try again later.')
    end
  end

  describe 'deploy key permissions' do
    let(:key) { create(:deploy_key, user: user) }
    let(:actor) { key }

    context 'when deploy_key can push' do
      context 'when project is authorized' do
        before do
          key.deploy_keys_projects.create(project: project, can_push: true)
        end

        it { expect { push_access_check }.not_to raise_error }
      end

      context 'when unauthorized' do
        context 'to public project' do
          let(:project) { create(:project, :public, :repository) }

          it { expect { push_access_check }.to raise_forbidden(described_class::ERROR_MESSAGES[:deploy_key_upload]) }
        end

        context 'to internal project' do
          let(:project) { create(:project, :internal, :repository) }

          it { expect { push_access_check }.to raise_not_found }
        end

        context 'to private project' do
          let(:project) { create(:project, :private, :repository) }

          it { expect { push_access_check }.to raise_not_found }
        end
      end
    end

    context 'when deploy_key cannot push' do
      context 'when project is authorized' do
        before do
          key.deploy_keys_projects.create(project: project, can_push: false)
        end

        it { expect { push_access_check }.to raise_forbidden(described_class::ERROR_MESSAGES[:deploy_key_upload]) }
      end

      context 'when unauthorized' do
        context 'to public project' do
          let(:project) { create(:project, :public, :repository) }

          it { expect { push_access_check }.to raise_forbidden(described_class::ERROR_MESSAGES[:deploy_key_upload]) }
        end

        context 'to internal project' do
          let(:project) { create(:project, :internal, :repository) }

          it { expect { push_access_check }.to raise_not_found }
        end

        context 'to private project' do
          let(:project) { create(:project, :private, :repository) }

          it { expect { push_access_check }.to raise_not_found }
        end
      end
    end
  end

  context 'terms are enforced' do
    before do
      enforce_terms
    end

    shared_examples 'access after accepting terms' do
      let(:actions) do
        [-> { pull_access_check },
         -> { push_access_check }]
      end

      it 'blocks access when the user did not accept terms', :aggregate_failures do
        actions.each do |action|
          expect { action.call }.to raise_forbidden(/must accept the Terms of Service in order to perform this action/)
        end
      end

      it 'allows access when the user accepted the terms', :aggregate_failures do
        accept_terms(user)

        actions.each do |action|
          expect { action.call }.not_to raise_error
        end
      end
    end

    describe 'as an anonymous user to a public project' do
      let(:actor) { nil }
      let(:project) { create(:project, :public, :repository) }

      it { expect { pull_access_check }.not_to raise_error }
    end

    describe 'as a guest to a public project' do
      let(:project) { create(:project, :public, :repository) }

      it_behaves_like 'access after accepting terms' do
        let(:actions) { [-> { pull_access_check }] }
      end
    end

    describe 'as a reporter to the project' do
      before do
        project.add_reporter(user)
      end

      it_behaves_like 'access after accepting terms' do
        let(:actions) { [-> { pull_access_check }] }
      end
    end

    describe 'as a developer of the project' do
      before do
        project.add_developer(user)
      end

      it_behaves_like 'access after accepting terms'
    end

    describe 'as a maintainer of the project' do
      before do
        project.add_maintainer(user)
      end

      it_behaves_like 'access after accepting terms'
    end

    describe 'as an owner of the project' do
      let(:project) { create(:project, :repository, namespace: user.namespace) }

      it_behaves_like 'access after accepting terms'
    end

    describe 'when a ci build clones the project' do
      let(:protocol) { 'http' }
      let(:authentication_abilities) { [:build_download_code] }
      let(:auth_result_type) { :build }

      before do
        project.add_developer(user)
      end

      it "doesn't block http pull" do
        aggregate_failures do
          expect { pull_access_check }.not_to raise_error
        end
      end
    end
  end

  private

  def access
    access_class.new(actor, project, protocol,
                        authentication_abilities: authentication_abilities,
                        repository_path: repository_path,
                        redirected_path: redirected_path, auth_result_type: auth_result_type)
  end

  def push_changes(changes)
    access.check('git-receive-pack', changes)
  end

  def raise_forbidden(message)
    raise_error(described_class::ForbiddenError, message)
  end

  def raise_not_found
    raise_error(described_class::NotFoundError, described_class::ERROR_MESSAGES[:project_not_found])
  end

  def build_authentication_abilities
    [
      :read_project,
      :build_download_code
    ]
  end

  def full_authentication_abilities
    [
      :read_project,
      :download_code,
      :push_code
    ]
  end
end
