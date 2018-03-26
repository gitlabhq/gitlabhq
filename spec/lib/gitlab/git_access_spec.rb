require 'spec_helper'

describe Gitlab::GitAccess do
  set(:user) { create(:user) }

  let(:actor) { user }
  let(:project) { create(:project, :repository) }
  let(:project_path) { project.path }
  let(:namespace_path) { project&.namespace&.path }
  let(:protocol) { 'ssh' }
  let(:authentication_abilities) { %i[read_project download_code push_code] }
  let(:redirected_path) { nil }

  let(:access) do
    described_class.new(actor, project,
      protocol, authentication_abilities: authentication_abilities,
                namespace_path: namespace_path, project_path: project_path,
                redirected_path: redirected_path)
  end

  let(:changes) { '_any' }
  let(:push_access_check) { access.check('git-receive-pack', changes) }
  let(:pull_access_check) { access.check('git-upload-pack', changes) }

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
          expect { push_access_check }.to raise_unauthorized('Git access over SSH is not allowed')
          expect { pull_access_check }.to raise_unauthorized('Git access over SSH is not allowed')
        end
      end
    end

    context 'http disabled' do
      let(:protocol) { 'http' }

      before do
        disable_protocol('http')
      end

      it 'blocks http push and pull' do
        aggregate_failures do
          expect { push_access_check }.to raise_unauthorized('Git access over HTTP is not allowed')
          expect { pull_access_check }.to raise_unauthorized('Git access over HTTP is not allowed')
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
              project.add_master(user)
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
            expect { push_access_check }.to raise_unauthorized(described_class::ERROR_MESSAGES[:auth_upload])
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
            expect { push_access_check }.to raise_unauthorized(described_class::ERROR_MESSAGES[:upload])
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

    context 'when the project is nil' do
      let(:project) { nil }
      let(:project_path) { "new-project" }

      it 'blocks push and pull with "not found"' do
        aggregate_failures do
          expect { pull_access_check }.to raise_not_found
          expect { push_access_check }.to raise_not_found
        end
      end

      context 'when user is allowed to create project in namespace' do
        let(:namespace_path) { user.namespace.path }
        let(:access) do
          described_class.new(actor, nil,
            protocol, authentication_abilities: authentication_abilities,
                      project_path: project_path, namespace_path: namespace_path,
                      redirected_path: redirected_path)
        end

        it 'blocks pull access with "not found"' do
          expect { pull_access_check }.to raise_not_found
        end

        it 'allows push access' do
          expect { push_access_check }.not_to raise_error
        end
      end

      context 'when user is not allowed to create project in namespace' do
        let(:user2) { create(:user) }
        let(:namespace_path) { user2.namespace.path }
        let(:access) do
          described_class.new(actor, nil,
            protocol, authentication_abilities: authentication_abilities,
                      project_path: project_path, namespace_path: namespace_path,
                      redirected_path: redirected_path)
        end

        it 'blocks push and pull with "not found"' do
          aggregate_failures do
            expect { pull_access_check }.to raise_not_found
            expect { push_access_check }.to raise_not_found
          end
        end
      end
    end
  end

  shared_examples '#check with a key that is not valid' do
    before do
      project.add_master(user)
    end

    context 'key is too small' do
      before do
        stub_application_setting(rsa_key_restriction: 4096)
      end

      it 'does not allow keys which are too small', :aggregate_failures do
        expect(actor).not_to be_valid
        expect { pull_access_check }.to raise_unauthorized('Your SSH key must be at least 4096 bits.')
        expect { push_access_check }.to raise_unauthorized('Your SSH key must be at least 4096 bits.')
      end
    end

    context 'key type is not allowed' do
      before do
        stub_application_setting(rsa_key_restriction: ApplicationSetting::FORBIDDEN_KEY_VALUE)
      end

      it 'does not allow keys which are too small', :aggregate_failures do
        expect(actor).not_to be_valid
        expect { pull_access_check }.to raise_unauthorized(/Your SSH key type is forbidden/)
        expect { push_access_check }.to raise_unauthorized(/Your SSH key type is forbidden/)
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

      expect(Gitlab::Checks::ProjectMoved.fetch_message(user.id, project.id)).not_to be_nil
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
      project.add_master(user)
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
      project.add_master(user)
    end

    context 'when download' do
      let(:authentication_abilities) { [] }

      it 'raises unauthorized with download error' do
        expect { pull_access_check }.to raise_unauthorized(described_class::ERROR_MESSAGES[:auth_download])
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
        expect { push_access_check }.to raise_unauthorized(described_class::ERROR_MESSAGES[:auth_upload])
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
      project.add_master(user)
    end

    context 'over http' do
      let(:protocol) { 'http' }

      context 'when the git-upload-pack command is disabled in config' do
        before do
          allow(Gitlab.config.gitlab_shell).to receive(:upload_pack).and_return(false)
        end

        context 'when calling git-upload-pack' do
          it { expect { pull_access_check }.to raise_unauthorized('Pulling over HTTP is not allowed.') }
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
          it { expect { push_access_check }.to raise_unauthorized('Pushing over HTTP is not allowed.') }
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

      it { expect { push_access_check }.to raise_unauthorized(described_class::ERROR_MESSAGES[:cannot_push_to_read_only]) }
    end
  end

  describe '#ensure_project_on_push!' do
    let(:access) do
      described_class.new(actor, project,
        protocol, authentication_abilities: authentication_abilities,
                  project_path: project_path, namespace_path: namespace_path,
                  redirected_path: redirected_path)
    end

    context 'when push' do
      let(:cmd) { 'git-receive-pack' }

      context 'when project does not exist' do
        let(:project_path) { "nonexistent" }
        let(:project) { nil }

        context 'when changes is _any' do
          let(:changes) { '_any' }

          context 'when authentication abilities include push code' do
            let(:authentication_abilities) { [:push_code] }

            context 'when user can create project in namespace' do
              let(:namespace_path) { user.namespace.path }

              it 'creates a new project' do
                expect { access.send(:ensure_project_on_push!, cmd, changes) }.to change { Project.count }.by(1)
              end
            end

            context 'when user cannot create project in namespace' do
              let(:user2) { create(:user) }
              let(:namespace_path) { user2.namespace.path }

              it 'does not create a new project' do
                expect { access.send(:ensure_project_on_push!, cmd, changes) }.not_to change { Project.count }
              end
            end
          end

          context 'when authentication abilities do not include push code' do
            let(:authentication_abilities) { [] }

            context 'when user can create project in namespace' do
              let(:namespace_path) { user.namespace.path }

              it 'does not create a new project' do
                expect { access.send(:ensure_project_on_push!, cmd, changes) }.not_to change { Project.count }
              end
            end
          end
        end

        context 'when check contains actual changes' do
          let(:changes) { "#{Gitlab::Git::BLANK_SHA} 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/new_branch" }

          it 'does not create a new project' do
            expect { access.send(:ensure_project_on_push!, cmd, changes) }.not_to change { Project.count }
          end
        end
      end

      context 'when project exists' do
        let(:changes) { '_any' }
        let!(:project) { create(:project) }

        it 'does not create a new project' do
          expect { access.send(:ensure_project_on_push!, cmd, changes) }.not_to change { Project.count }
        end
      end

      context 'when deploy key is used' do
        let(:key) { create(:deploy_key, user: user) }
        let(:actor) { key }
        let(:project_path) { "nonexistent" }
        let(:project) { nil }
        let(:namespace_path) { user.namespace.path }
        let(:changes) { '_any' }

        it 'does not create a new project' do
          expect { access.send(:ensure_project_on_push!, cmd, changes) }.not_to change { Project.count }
        end
      end
    end

    context 'when pull' do
      let(:cmd) { 'git-upload-pack' }
      let(:changes) { '_any' }

      context 'when project does not exist' do
        let(:project_path) { "new-project" }
        let(:namespace_path) { user.namespace.path }
        let(:project) { nil }

        it 'does not create a new project' do
          expect { access.send(:ensure_project_on_push!, cmd, changes) }.not_to change { Project.count }
        end
      end
    end
  end

  describe '#check_download_access!' do
    it 'allows masters to pull' do
      project.add_master(user)

      expect { pull_access_check }.not_to raise_error
    end

    it 'disallows guests to pull' do
      project.add_guest(user)

      expect { pull_access_check }.to raise_unauthorized(described_class::ERROR_MESSAGES[:download])
    end

    it 'disallows blocked users to pull' do
      project.add_master(user)
      user.block

      expect { pull_access_check }.to raise_unauthorized('Your account has been blocked.')
    end

    context 'when the project repository does not exist' do
      it 'returns not found' do
        project.add_guest(user)
        repo = project.repository
        FileUtils.rm_rf(repo.path)

        # Sanity check for rm_rf
        expect(repo.exists?).to eq(false)

        expect { pull_access_check }.to raise_error(Gitlab::GitAccess::NotFoundError, 'A repository for this project does not exist yet.')
      end
    end

    describe 'without access to project' do
      context 'pull code' do
        it { expect { pull_access_check }.to raise_not_found }
      end

      context 'when project is public' do
        let(:public_project) { create(:project, :public, :repository) }
        let(:project_path) { public_project.path }
        let(:namespace_path) { public_project.namespace.path }
        let(:access) { described_class.new(nil, public_project, 'web', authentication_abilities: [:download_code], project_path: project_path, namespace_path: namespace_path) }

        context 'when repository is enabled' do
          it 'give access to download code' do
            expect { pull_access_check }.not_to raise_error
          end
        end

        context 'when repository is disabled' do
          it 'does not give access to download code' do
            public_project.project_feature.update_attribute(:repository_access_level, ProjectFeature::DISABLED)

            expect { pull_access_check }.to raise_unauthorized(described_class::ERROR_MESSAGES[:download])
          end
        end
      end
    end

    describe 'deploy key permissions' do
      let(:key) { create(:deploy_key, user: user) }
      let(:actor) { key }

      context 'pull code' do
        context 'when project is authorized' do
          before do
            key.projects << project
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
            it { expect { pull_access_check }.to raise_unauthorized(described_class::ERROR_MESSAGES[:download]) }
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

    it 'checks LFS integrity only for first change' do
      expect_any_instance_of(Gitlab::Checks::LfsIntegrity).to receive(:objects_missing?).exactly(1).times

      push_access_check
    end
  end

  describe '#check_push_access!' do
    let(:unprotected_branch) { 'unprotected_branch' }

    before do
      merge_into_protected_branch
    end

    let(:changes) do
      { push_new_branch: "#{Gitlab::Git::BLANK_SHA} 570e7b2ab refs/heads/wow",
        push_master: '6f6d7e7ed 570e7b2ab refs/heads/master',
        push_protected_branch: '6f6d7e7ed 570e7b2ab refs/heads/feature',
        push_remove_protected_branch: "570e7b2ab #{Gitlab::Git::BLANK_SHA} "\
                                      'refs/heads/feature',
        push_tag: '6f6d7e7ed 570e7b2ab refs/tags/v1.0.0',
        push_new_tag: "#{Gitlab::Git::BLANK_SHA} 570e7b2ab refs/tags/v7.8.9",
        push_all: ['6f6d7e7ed 570e7b2ab refs/heads/master', '6f6d7e7ed 570e7b2ab refs/heads/feature'],
        merge_into_protected_branch: "0b4bc9a #{merge_into_protected_branch} refs/heads/feature" }
    end

    def stub_git_hooks
      # Running the `pre-receive` hook is expensive, and not necessary for this test.
      allow_any_instance_of(Gitlab::Git::HooksService).to receive(:execute) do |service, &block|
        block.call(service)
      end
    end

    def merge_into_protected_branch
      @protected_branch_merge_commit ||= begin
        stub_git_hooks
        project.repository.add_branch(user, unprotected_branch, 'feature')
        target_branch = project.repository.lookup('feature')
        source_branch = project.repository.create_file(
          user,
          'filename',
          'This is the file content',
          message: 'This is a good commit message',
          branch_name: unprotected_branch)
        rugged = project.repository.rugged
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
          if role == :admin
            user.update_attribute(:admin, true)
          else
            project.add_role(user, role)
          end

          aggregate_failures do
            matrix.each do |action, allowed|
              check = -> { access.send(:check_push_access!, changes[action]) }

              if allowed
                expect(&check).not_to raise_error,
                  -> { "expected #{action} to be allowed" }
              else
                expect(&check).to raise_error(Gitlab::GitAccess::UnauthorizedError),
                  -> { "expected #{action} to be disallowed" }
              end
            end
          end
        end
      end
    end

    # Run permission checks for a group
    def self.run_group_permission_checks(permissions_matrix)
      permissions_matrix.each_pair do |role, matrix|
        it "has the correct permissions for group #{role}s" do
          project
            .project_group_links
            .create(group: group, group_access: Gitlab::Access.sym_options[role])

          aggregate_failures do
            matrix.each do |action, allowed|
              check = -> { access.send(:check_push_access!, changes[action]) }

              if allowed
                expect(&check).not_to raise_error,
                  -> { "expected #{action} to be allowed" }
              else
                expect(&check).to raise_error(Gitlab::GitAccess::UnauthorizedError),
                  -> { "expected #{action} to be disallowed" }
              end
            end
          end
        end
      end
    end

    permissions_matrix = {
      admin: {
        push_new_branch: true,
        push_master: true,
        push_protected_branch: true,
        push_remove_protected_branch: false,
        push_tag: true,
        push_new_tag: true,
        push_all: true,
        merge_into_protected_branch: true
      },

      master: {
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
        push_new_branch: true,
        push_master: true,
        push_protected_branch: false,
        push_remove_protected_branch: false,
        push_tag: false,
        push_new_tag: true,
        push_all: false,
        merge_into_protected_branch: false
      },

      reporter: {
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
        before do
          create(:protected_branch, :masters_can_push, name: protected_branch_name, project: project)
        end

        run_permission_checks(permissions_matrix)
      end

      context "when developers are allowed to push into the #{protected_branch_type} protected branch" do
        before do
          create(:protected_branch, :masters_can_push, :developers_can_push, name: protected_branch_name, project: project)
        end

        run_permission_checks(permissions_matrix.deep_merge(developer: { push_protected_branch: true, push_all: true, merge_into_protected_branch: true }))
      end

      context "developers are allowed to merge into the #{protected_branch_type} protected branch" do
        before do
          create(:protected_branch, :masters_can_push, :developers_can_merge, name: protected_branch_name, project: project)
        end

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
        before do
          create(:protected_branch, :masters_can_push, :developers_can_merge, :developers_can_push, name: protected_branch_name, project: project)
        end

        run_permission_checks(permissions_matrix.deep_merge(developer: { push_protected_branch: true, push_all: true, merge_into_protected_branch: true }))
      end

      context "user-specific access control" do
        context "when a specific user is allowed to push into the #{protected_branch_type} protected branch" do
          let(:user) { create(:user) }

          before do
            create(:protected_branch, authorize_user_to_push: user, name: protected_branch_name, project: project)
          end

          run_permission_checks(permissions_matrix.deep_merge(developer: { push_protected_branch: true, push_all: true, merge_into_protected_branch: true },
                                                              guest: { push_protected_branch: false, merge_into_protected_branch: false },
                                                              reporter: { push_protected_branch: false, merge_into_protected_branch: false }))
        end

        context "when a specific user is allowed to merge into the #{protected_branch_type} protected branch" do
          let(:user) { create(:user) }

          before do
            create(:merge_request, source_project: project, source_branch: unprotected_branch, target_branch: 'feature', state: 'locked', in_progress_merge_commit_sha: merge_into_protected_branch)
            create(:protected_branch, authorize_user_to_merge: user, name: protected_branch_name, project: project)
          end

          run_permission_checks(permissions_matrix.deep_merge(admin: { push_protected_branch: false, push_all: false, merge_into_protected_branch: true },
                                                              master: { push_protected_branch: false, push_all: false, merge_into_protected_branch: true },
                                                              developer: { push_protected_branch: false, push_all: false, merge_into_protected_branch: true },
                                                              guest: { push_protected_branch: false, merge_into_protected_branch: false },
                                                              reporter: { push_protected_branch: false, merge_into_protected_branch: false }))
        end

        context "when a specific user is allowed to push & merge into the #{protected_branch_type} protected branch" do
          let(:user) { create(:user) }

          before do
            create(:merge_request, source_project: project, source_branch: unprotected_branch, target_branch: 'feature', state: 'locked', in_progress_merge_commit_sha: merge_into_protected_branch)
            create(:protected_branch, authorize_user_to_push: user, authorize_user_to_merge: user, name: protected_branch_name, project: project)
          end

          run_permission_checks(permissions_matrix.deep_merge(developer: { push_protected_branch: true, push_all: true, merge_into_protected_branch: true },
                                                              guest: { push_protected_branch: false, merge_into_protected_branch: false },
                                                              reporter: { push_protected_branch: false, merge_into_protected_branch: false }))
        end
      end

      context "group-specific access control" do
        context "when a specific group is allowed to push into the #{protected_branch_type} protected branch" do
          let(:user) { create(:user) }
          let(:group) { create(:group) }

          before do
            group.add_master(user)
            create(:protected_branch, authorize_group_to_push: group, name: protected_branch_name, project: project)
          end

          permissions = permissions_matrix.except(:admin).deep_merge(developer: { push_protected_branch: true, push_all: true, merge_into_protected_branch: true },
                                                                     guest: { push_protected_branch: false, merge_into_protected_branch: false },
                                                                     reporter: { push_protected_branch: false, merge_into_protected_branch: false })

          run_group_permission_checks(permissions)
        end

        context "when a specific group is allowed to merge into the #{protected_branch_type} protected branch" do
          let(:user) { create(:user) }
          let(:group) { create(:group) }

          before do
            group.add_master(user)
            create(:merge_request, source_project: project, source_branch: unprotected_branch, target_branch: 'feature', state: 'locked', in_progress_merge_commit_sha: merge_into_protected_branch)
            create(:protected_branch, authorize_group_to_merge: group, name: protected_branch_name, project: project)
          end

          permissions = permissions_matrix.except(:admin).deep_merge(master: { push_protected_branch: false, push_all: false, merge_into_protected_branch: true },
                                                                     developer: { push_protected_branch: false, push_all: false, merge_into_protected_branch: true },
                                                                     guest: { push_protected_branch: false, merge_into_protected_branch: false },
                                                                     reporter: { push_protected_branch: false, merge_into_protected_branch: false })

          run_group_permission_checks(permissions)
        end

        context "when a specific group is allowed to push & merge into the #{protected_branch_type} protected branch" do
          let(:user) { create(:user) }
          let(:group) { create(:group) }

          before do
            group.add_master(user)
            create(:merge_request, source_project: project, source_branch: unprotected_branch, target_branch: 'feature', state: 'locked', in_progress_merge_commit_sha: merge_into_protected_branch)
            create(:protected_branch, authorize_group_to_push: group, authorize_group_to_merge: group, name: protected_branch_name, project: project)
          end

          permissions = permissions_matrix.except(:admin).deep_merge(developer: { push_protected_branch: true, push_all: true, merge_into_protected_branch: true },
                                                                     guest: { push_protected_branch: false, merge_into_protected_branch: false },
                                                                     reporter: { push_protected_branch: false, merge_into_protected_branch: false })

          run_group_permission_checks(permissions)
        end
      end

      context "when no one is allowed to push to the #{protected_branch_name} protected branch" do
        before do
          create(:protected_branch, :no_one_can_push, name: protected_branch_name, project: project)
        end

        run_permission_checks(permissions_matrix.deep_merge(developer: { push_protected_branch: false, push_all: false, merge_into_protected_branch: false },
                                                            master: { push_protected_branch: false, push_all: false, merge_into_protected_branch: false },
                                                            admin: { push_protected_branch: false, push_all: false, merge_into_protected_branch: false }))
      end
    end

    describe "push_rule_check" do
      let(:start_sha) { '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9' }
      let(:end_sha)   { '570e7b2abdd848b95f2f578043fc23bd6f6fd24d' }

      before do
        project.add_developer(user)

        allow(project.repository).to receive(:new_commits)
          .and_return(project.repository.commits_between(start_sha, end_sha))
      end

      describe "author email check" do
        it 'returns true' do
          expect { access.send(:check_push_access!, "#{start_sha} #{end_sha} refs/heads/master") }.not_to raise_error
        end

        it 'returns false' do
          project.create_push_rule(commit_message_regex: "@only.com")

          expect { access.send(:check_push_access!, "#{start_sha} #{end_sha} refs/heads/master") }.to raise_error(described_class::UnauthorizedError)
        end

        it 'returns true for tags' do
          project.create_push_rule(commit_message_regex: "@only.com")

          expect { access.send(:check_push_access!, "#{start_sha} #{end_sha} refs/tags/v1") }.not_to raise_error
        end

        it 'allows githook for new branch with an old bad commit' do
          bad_commit = double("Commit", safe_message: 'Some change').as_null_object
          ref_object = double(name: 'heads/master')
          allow(bad_commit).to receive(:refs).and_return([ref_object])
          allow_any_instance_of(Repository).to receive(:commits_between).and_return([bad_commit])

          project.create_push_rule(commit_message_regex: "Change some files")

          # push to new branch, so use a blank old rev and new ref
          expect { access.send(:check_push_access!, "#{Gitlab::Git::BLANK_SHA} #{end_sha} refs/heads/new-branch") }.not_to raise_error
        end

        it 'allows githook for any change with an old bad commit' do
          bad_commit = double("Commit", safe_message: 'Some change').as_null_object
          ref_object = double(name: 'heads/master')
          allow(bad_commit).to receive(:refs).and_return([ref_object])
          allow(project.repository).to receive(:commits_between).and_return([bad_commit])

          project.create_push_rule(commit_message_regex: "Change some files")

          # push to new branch, so use a blank old rev and new ref
          expect { access.send(:check_push_access!, "#{start_sha} #{end_sha} refs/heads/master") }.not_to raise_error
        end

        it 'does not allow any change from Web UI with bad commit' do
          bad_commit = double("Commit", safe_message: 'Some change').as_null_object
          # We use tmp ref a a temporary for Web UI commiting
          ref_object = double(name: 'refs/tmp')
          allow(bad_commit).to receive(:refs).and_return([ref_object])
          allow(project.repository).to receive(:commits_between).and_return([bad_commit])
          allow(project.repository).to receive(:new_commits).and_return([bad_commit])

          project.create_push_rule(commit_message_regex: "Change some files")

          # push to new branch, so use a blank old rev and new ref
          expect { access.send(:check_push_access!, "#{start_sha} #{end_sha} refs/heads/master") }.to raise_error(described_class::UnauthorizedError)
        end
      end

      describe "member_check" do
        before do
          project.create_push_rule(member_check: true)
        end

        it 'returns false for non-member user' do
          expect { access.send(:check_push_access!, "#{start_sha} #{end_sha} refs/heads/master") }.to raise_error(described_class::UnauthorizedError)
        end

        it 'returns true if committer is a gitlab member' do
          create(:user, email: 'dmitriy.zaporozhets@gmail.com')

          expect { access.send(:check_push_access!, "#{start_sha} #{end_sha} refs/heads/master") }.not_to raise_error
        end
      end

      describe "file names check" do
        let(:start_sha) { '913c66a37b4a45b9769037c55c2d238bd0942d2e' }
        let(:end_sha)   { '33f3729a45c02fc67d00adb1b8bca394b0e761d9' }

        before do
          allow(project.repository).to receive(:new_commits)
            .and_return(project.repository.commits_between(start_sha, end_sha))
        end

        it 'returns false when filename is prohibited' do
          project.create_push_rule(file_name_regex: "jpg$")

          expect { access.send(:check_push_access!, "#{start_sha} #{end_sha} refs/heads/master") }.to raise_error(described_class::UnauthorizedError)
        end

        it 'returns true if file name is allowed' do
          project.create_push_rule(file_name_regex: "exe$")

          expect { access.send(:check_push_access!, "#{start_sha} #{end_sha} refs/heads/master") }.not_to raise_error
        end
      end

      describe "max file size check" do
        let(:start_sha) { 'cfe32cf61b73a0d5e9f13e774abde7ff789b1660' }
        let(:end_sha)   { '913c66a37b4a45b9769037c55c2d238bd0942d2e' }

        before do
          allow_any_instance_of(Gitlab::Git::Blob).to receive(:size).and_return(1.5.megabytes.to_i)
        end

        it "returns false when size is too large" do
          project.create_push_rule(max_file_size: 1)

          expect { access.send(:check_push_access!, "#{start_sha} #{end_sha} refs/heads/master") }.to raise_error(described_class::UnauthorizedError)
        end

        it "returns true when size is allowed" do
          project.create_push_rule(max_file_size: 2)

          expect { access.send(:check_push_access!, "#{start_sha} #{end_sha} refs/heads/master") }.not_to raise_error
        end

        it "returns true when size is nil" do
          allow_any_instance_of(Gitlab::Git::Blob).to receive(:size).and_return(nil)
          project.create_push_rule(max_file_size: 2)

          expect { access.send(:check_push_access!, "#{start_sha} #{end_sha} refs/heads/master") }.not_to raise_error
        end
      end

      describe 'repository size restrictions' do
        before do
          project.update_attribute(:repository_size_limit, 50.megabytes)
        end

        it 'returns false when blob is too big' do
          allow_any_instance_of(Gitlab::Git::Blob).to receive(:size).and_return(100.megabytes.to_i)

          expect { access.send(:check_push_access!, "#{start_sha} #{end_sha} refs/heads/master") }.to raise_error(described_class::UnauthorizedError)
        end

        it 'returns true when blob is just right' do
          allow_any_instance_of(Gitlab::Git::Blob).to receive(:size).and_return(2.megabytes.to_i)

          expect { access.send(:check_push_access!, "#{start_sha} #{end_sha} refs/heads/master") }.not_to raise_error
        end
      end
    end
  end

  describe 'build authentication abilities' do
    let(:authentication_abilities) { build_authentication_abilities }

    context 'when project is authorized' do
      before do
        project.add_reporter(user)
      end

      it { expect { push_access_check }.to raise_unauthorized(described_class::ERROR_MESSAGES[:auth_upload]) }
    end

    context 'when unauthorized' do
      context 'to public project' do
        let(:project) { create(:project, :public, :repository) }

        it { expect { push_access_check }.to raise_unauthorized(described_class::ERROR_MESSAGES[:auth_upload]) }
      end

      context 'to internal project' do
        let(:project) { create(:project, :internal, :repository) }

        it { expect { push_access_check }.to raise_unauthorized(described_class::ERROR_MESSAGES[:auth_upload]) }
      end

      context 'to private project' do
        let(:project) { create(:project, :private, :repository) }

        it { expect { push_access_check }.to raise_unauthorized(described_class::ERROR_MESSAGES[:auth_upload]) }
      end
    end
  end

  context 'when the repository is read only' do
    let(:project) { create(:project, :repository, :read_only) }

    it 'denies push access' do
      project.add_master(user)

      expect { push_access_check }.to raise_unauthorized('The repository is temporarily read-only. Please try again later.')
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

          it { expect { push_access_check }.to raise_unauthorized(described_class::ERROR_MESSAGES[:deploy_key_upload]) }
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

        it { expect { push_access_check }.to raise_unauthorized(described_class::ERROR_MESSAGES[:deploy_key_upload]) }
      end

      context 'when unauthorized' do
        context 'to public project' do
          let(:project) { create(:project, :public, :repository) }

          it { expect { push_access_check }.to raise_unauthorized(described_class::ERROR_MESSAGES[:deploy_key_upload]) }
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

  describe 'Geo system permissions' do
    let(:actor) { :geo }

    it { expect { pull_access_check }.not_to raise_error }
    it { expect { push_access_check }.to raise_unauthorized(Gitlab::GitAccess::ERROR_MESSAGES[:upload]) }
  end

  private

  def raise_unauthorized(message)
    raise_error(Gitlab::GitAccess::UnauthorizedError, message)
  end

  def raise_not_found
    raise_error(Gitlab::GitAccess::NotFoundError, Gitlab::GitAccess::ERROR_MESSAGES[:project_not_found])
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
