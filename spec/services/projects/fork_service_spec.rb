# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ForkService, feature_category: :source_code_management do
  subject(:service) { described_class.new(project, user, params) }

  let_it_be_with_reload(:project) { create(:project, :repository, star_count: 100, description: 'project') }
  let_it_be_with_reload(:user) { create(:user) }

  let(:params) { { namespace: namespace } }
  let(:namespace) { user.namespace }

  shared_examples 'forks count cache refresh' do
    it 'flushes the forks count cache of the source project', :clean_gitlab_redis_cache do
      expect(from_project.forks_count).to be_zero

      described_class.new(from_project, to_user, params).execute

      BatchLoader::Executor.clear_current

      expect(from_project.reload.forks_count).to eq(1)
    end
  end

  describe '#execute' do
    subject(:response) { service.execute }

    let(:fork_of_project) { response[:project] }

    before do
      # NOTE: Avatar file is dropped after project reload. Explicitly re-add it for each test.
      project.avatar = fixture_file_upload("spec/fixtures/dk.png", "image/png")
    end

    context 'when forker is a guest' do
      before do
        project.add_member(user, :guest)
      end

      it 'does not create a fork' do
        is_expected.to be_error
        expect(response.errors).to eq(['Forked from project is forbidden'])
      end

      it 'does not create a fork network' do
        expect { subject }.not_to change { project.reload.fork_network }
      end
    end

    context 'when forker is a developer' do
      before do
        project.add_member(user, :developer)
      end

      it 'creates a fork of the project' do
        is_expected.to be_success
        expect(fork_of_project.errors).to be_empty
        expect(fork_of_project.first_owner).to eq(user)
        expect(fork_of_project.namespace).to eq(user.namespace)
        expect(fork_of_project.star_count).to be_zero
        expect(fork_of_project.description).to eq(project.description)
        expect(fork_of_project.avatar.file).to be_exists
        expect(fork_of_project.ci_config_path).to eq(project.ci_config_path)
        expect(fork_of_project.external_authorization_classification_label).to eq(project.external_authorization_classification_label)
        expect(fork_of_project.suggestion_commit_message).to eq(project.suggestion_commit_message)
        expect(fork_of_project.merge_commit_template).to eq(project.merge_commit_template)
        expect(fork_of_project.squash_commit_template).to eq(project.squash_commit_template)
      end

      # This test is here because we had a bug where the from-project lost its
      # avatar after being forked.
      # https://gitlab.com/gitlab-org/gitlab-foss/issues/26158
      it 'after forking the original project still has its avatar' do
        # If we do not fork the project first we cannot detect the bug.
        is_expected.to be_success

        expect(project.avatar.file).to be_exists
      end

      it_behaves_like 'forks count cache refresh' do
        let(:from_project) { project }
        let(:to_user) { user }
      end

      it 'creates a fork network with the new project and the root project set' do
        subject

        fork_network = project.reload.fork_network

        expect(fork_network).not_to be_nil
        expect(fork_network.root_project).to eq(project)
        expect(fork_network.projects).to contain_exactly(project, fork_of_project)
      end

      it 'imports the repository of the forked project', :sidekiq_might_not_need_inline do
        expect(fork_of_project).to be_persisted

        # The call to project.repository.after_import in RepositoryForkWorker does
        # not reset the @exists variable of this fork_of_project.repository
        # so we have to explicitly call this method to clear the @exists variable.
        # of the instance we're returning here.
        fork_of_project.repository.expire_content_cache

        expect(fork_of_project.empty_repo?).to be_falsey
      end

      context 'when creating fork of the fork' do
        let_it_be(:other_namespace) { create(:group, owners: user) }

        it 'creates a new project' do
          fork_response = described_class.new(project, user, params).execute
          expect(fork_response).to be_success

          fork_of_project = fork_response[:project]
          expect(fork_of_project).to be_persisted

          fork_of_fork_response = described_class.new(fork_of_project, user, { namespace: other_namespace }).execute
          expect(fork_of_fork_response).to be_success

          fork_of_fork = fork_of_fork_response[:project]
          expect(fork_of_fork).to be_persisted

          expect(fork_of_fork).to be_valid
          expect(fork_of_fork.fork_network.root_project).to eq(project)
          expect(fork_of_fork.fork_network_member.forked_from_project).to eq(fork_of_project)
        end

        context 'when the forked project has higher visibility than the root project' do
          let_it_be(:root_project) { create(:project, :public) }

          it 'successfully creates a fork of the fork with correct visibility' do
            fork_response = described_class.new(root_project, user, params).execute
            expect(fork_response).to be_success

            fork_of_project = fork_response[:project]
            expect(fork_of_project).to be_persisted

            root_project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)

            # Forked project visibility is not affected by root project visibility change
            expect(fork_of_project).to have_attributes(visibility_level: Gitlab::VisibilityLevel::PUBLIC)

            fork_of_fork_response = described_class.new(fork_of_project, user, { namespace: other_namespace }).execute
            expect(fork_of_fork_response).to be_success

            fork_of_fork = fork_of_fork_response[:project]
            expect(fork_of_fork).to be_persisted

            expect(fork_of_fork).to be_valid
            expect(fork_of_fork).to have_attributes(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          end
        end

        it_behaves_like 'forks count cache refresh' do
          let(:from_project) { described_class.new(project, user, { namespace: other_namespace }).execute[:project] }
          let(:to_user) { user }
        end
      end

      context 'when project already exists' do
        it 'fails due to validation, not transaction failure' do
          existing_project = create(:project, namespace: namespace, path: project.path)
          expect(existing_project).to be_persisted

          is_expected.to be_error
          expect(response.errors).to include('Path has already been taken')
        end
      end

      context 'when repository in legacy storage already exists' do
        let(:raw_fake_repo) { Gitlab::Git::Repository.new('default', File.join(user.namespace.full_path, "#{project.path}.git"), nil, nil) }

        before do
          stub_application_setting(hashed_storage_enabled: false)
          raw_fake_repo.create_repository
        end

        after do
          raw_fake_repo.remove
        end

        it 'does not allow creation' do
          is_expected.to be_error

          expect(response.errors).to include('There is already a repository with that name on disk')
        end

        context 'when repository disk validation is explicitly skipped' do
          let(:params) { super().merge(skip_disk_validation: true) }

          it 'allows fork project creation' do
            is_expected.to be_success

            expect(fork_of_project).to be_persisted
            expect(fork_of_project.errors.messages).to be_empty
          end
        end
      end

      context 'CI/CD settings' do
        context 'when origin has git depth specified' do
          it 'inherits default_git_depth from the origin project' do
            project.update!(ci_default_git_depth: 42)

            is_expected.to be_success
            expect(fork_of_project).to be_persisted
            expect(fork_of_project.ci_default_git_depth).to eq(42)
          end
        end

        context 'when origin does not define git depth' do
          it 'the fork has git depth set to 0' do
            project.update!(ci_default_git_depth: nil)

            is_expected.to be_success
            expect(fork_of_project).to be_persisted
            expect(fork_of_project.ci_default_git_depth).to eq(0)
          end
        end
      end

      context 'when project has restricted visibility level' do
        context 'and only one visibility level is restricted' do
          before do
            project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
            stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::INTERNAL])
          end

          it 'creates fork with lowest level' do
            is_expected.to be_success
            expect(fork_of_project).to be_persisted
            expect(fork_of_project.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
          end
        end

        context "and all visibility levels are restricted" do
          before do
            stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC, Gitlab::VisibilityLevel::INTERNAL, Gitlab::VisibilityLevel::PRIVATE])
          end

          it "doesn't create a fork" do
            is_expected.to be_error
            expect(response.errors).to eq ['Visibility level private has been restricted by your GitLab administrator']
          end
        end
      end

      context 'when forking is disabled' do
        before do
          project.project_feature.update_attribute(:forking_access_level, ProjectFeature::DISABLED)
        end

        it 'does not create a fork' do
          is_expected.to be_error
          expect(response.errors).to eq(['Forked from project is forbidden'])
        end
      end

      context 'when forking to the group namespace' do
        context 'when user owns a target group' do
          let_it_be_with_reload(:namespace) { create(:group, owners: user) }

          it 'creates a fork in the group' do
            is_expected.to be_success

            expect(fork_of_project.first_owner).to eq(user)
            expect(fork_of_project.namespace).to eq(namespace)
          end

          context 'when project already exists in group' do
            it 'fails due to validation, not transaction failure' do
              existing_project = create(:project, :repository, path: project.path, namespace: namespace)
              expect(existing_project).to be_persisted

              is_expected.to be_error
              expect(response.errors).to include('Path has already been taken')
            end
          end

          context 'when the namespace has a lower visibility level than the project' do
            let_it_be(:namespace) { create(:group, :private, owners: user) }
            let_it_be(:project) { create(:project, :public) }

            it 'creates the project with the lower visibility level' do
              is_expected.to be_success
              expect(fork_of_project).to be_persisted
              expect(fork_of_project.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            end
          end
        end

        context 'when user is not a group owner' do
          let_it_be(:namespace) { create(:group, developers: user) }

          it 'does not create a fork' do
            is_expected.to be_error
            expect(response.errors).to match_array(['Namespace is not valid', 'User is not allowed to import projects'])
          end
        end
      end

      context 'with optional attributes' do
        let(:params) { super().merge(path: 'forked', name: 'My Fork', description: 'Description', visibility: 'private') }

        it 'sets optional attributes to specified values' do
          is_expected.to be_success

          expect(fork_of_project).to be_persisted
          expect(fork_of_project.path).to eq('forked')
          expect(fork_of_project.name).to eq('My Fork')
          expect(fork_of_project.description).to eq('Description')
          expect(fork_of_project.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
        end

        context 'when an unknown visibility is requested' do
          let_it_be(:project) { create(:project, :public) }

          let(:params) { super().merge(visibility: 'unknown') }

          it 'sets visibility level to private' do
            is_expected.to be_success

            expect(fork_of_project).to be_persisted
            expect(fork_of_project.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
          end
        end

        context 'when requested visibility level is greater than allowed' do
          let_it_be(:project) { create(:project, :internal) }

          let(:params) { super().merge(visibility: 'public') }

          it 'sets visibility level to project visibility' do
            is_expected.to be_success

            expect(fork_of_project).to be_persisted
            expect(fork_of_project.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
          end
        end

        context 'when target namespace has lower visibility than a project' do
          let_it_be(:project) { create(:project, :public) }
          let_it_be(:namespace) { create(:group, :private, owners: user) }

          it 'sets visibility level to target namespace visibility level' do
            is_expected.to be_success

            expect(fork_of_project).to be_persisted
            expect(fork_of_project.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
          end
        end

        context 'when project has custom visibility settings' do
          let_it_be(:project) { create(:project, :public) }

          let(:attrs) do
            ProjectFeature::FEATURES.to_h do |f|
              ["#{f}_access_level", ProjectFeature::PRIVATE]
            end
          end

          before do
            project.project_feature.update!(attrs)
          end

          it 'copies project features visibility settings to the fork' do
            is_expected.to be_success

            expect(fork_of_project).to be_persisted
            expect(fork_of_project.project_feature.slice(attrs.keys)).to eq(attrs)
          end
        end
      end

      context 'when a project is already forked' do
        let_it_be(:project) { create(:project, :public, :repository) }
        let_it_be(:group) { create(:group, owners: user) }

        before do
          # Stub everything required to move a project to a Gitaly shard that does not exist
          allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('default').and_call_original
          allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('test_second_storage').and_return(SecureRandom.uuid)
          stub_storage_settings('test_second_storage' => {})
          allow_any_instance_of(Gitlab::Git::Repository).to receive(:create_repository)
                                                              .and_return(true)
          allow_any_instance_of(Gitlab::Git::Repository).to receive(:replicate)
          allow_any_instance_of(Gitlab::Git::Repository).to receive(:checksum)
                                                              .and_return(::Gitlab::Git::SHA1_BLANK_SHA)
          allow_next_instance_of(Gitlab::Git::ObjectPool) do |object_pool|
            allow(object_pool).to receive(:link)
          end
        end

        it 'creates a new pool repository after the project is moved to a new shard' do
          fork_before_move = fork_of_project

          storage_move = create(
            :project_repository_storage_move,
            :scheduled,
            container: project,
            destination_storage_name: 'test_second_storage'
          )
          Projects::UpdateRepositoryStorageService.new(storage_move).execute

          fork_after_move_response = described_class.new(project.reload, user, namespace: group).execute
          expect(fork_after_move_response).to be_success

          fork_after_move = fork_after_move_response[:project]
          pool_repository_before_move = PoolRepository.joins(:shard)
                                          .find_by(source_project: project, shards: { name: 'default' })
          pool_repository_after_move = PoolRepository.joins(:shard)
                                         .find_by(source_project: project, shards: { name: 'test_second_storage' })

          expect(fork_before_move.pool_repository).to eq(pool_repository_before_move)
          expect(fork_after_move.pool_repository).to eq(pool_repository_after_move)
        end
      end

      context 'when forking with object pools' do
        let_it_be(:project) { create(:project, :public, :repository) }

        context 'when no pool exists' do
          it 'creates a new object pool' do
            expect { response }.to change { PoolRepository.count }.by(1)

            is_expected.to be_success
            expect(fork_of_project.pool_repository).to eq(project.pool_repository)
          end

          context 'when project is private' do
            let_it_be(:project) { create(:project, :private, :repository) }

            it 'does not create an object pool' do
              expect { response }.not_to change { PoolRepository.count }

              is_expected.to be_success
              expect(fork_of_project.pool_repository).to be_nil
            end
          end
        end

        context 'when a pool already exists' do
          let!(:pool_repository) { create(:pool_repository, source_project: project) }

          it 'joins the object pool' do
            expect { response }.not_to change { PoolRepository.count }

            is_expected.to be_success
            expect(fork_of_project.pool_repository).to eq(pool_repository)
          end
        end
      end

      context 'when linking fork to an existing project' do
        let_it_be_with_reload(:unlinked_fork) { create(:project, :public) }

        before_all do
          unlinked_fork.add_developer(user)
        end

        def forked_from_project(project)
          project.fork_network_member&.forked_from_project
        end

        context 'if project is already forked' do
          it 'does not create fork relation' do
            allow(unlinked_fork).to receive(:forked?).and_return(true)

            expect(forked_from_project(unlinked_fork)).to be_nil

            expect(service.execute(unlinked_fork)).to be_error

            expect(forked_from_project(unlinked_fork)).to be_nil
          end
        end

        context 'if project is not forked' do
          it 'creates fork relation' do
            expect(unlinked_fork.forked?).to be_falsy
            expect(forked_from_project(unlinked_fork)).to be_nil

            service.execute(unlinked_fork)

            unlinked_fork.reload

            expect(unlinked_fork.forked?).to be true
            expect(forked_from_project(unlinked_fork)).to eq project
            expect(unlinked_fork.forked_from_project).to eq project
          end

          it 'flushes the forks count cache of the source project' do
            expect(project.forks_count).to be_zero

            service.execute(unlinked_fork)
            BatchLoader::Executor.clear_current

            expect(project.forks_count).to eq(1)
          end

          context 'when user cannot fork' do
            let(:another_user) { create(:user) }

            it 'returns an error' do
              expect(unlinked_fork.forked?).to be_falsey
              expect(forked_from_project(unlinked_fork)).to be_nil

              response = described_class.new(project, another_user, params).execute(unlinked_fork)
              expect(response).to be_error
              expect(response.errors).to eq ['Forked from project is forbidden']

              expect(forked_from_project(unlinked_fork)).to be_nil
            end
          end

          context 'if the fork is not allowed' do
            let_it_be(:project) { create(:project, :private) }

            it 'does not delete the LFS objects' do
              create(:lfs_objects_project, project: unlinked_fork)

              expect { service.execute(unlinked_fork) }
                .not_to change { unlinked_fork.lfs_objects_projects.size }
            end
          end
        end
      end
    end
  end

  describe '#valid_fork_targets' do
    subject { service.valid_fork_targets }

    let(:finder_mock) { instance_double('ForkTargetsFinder', execute: ['finder_return_value']) }

    before do
      allow(ForkTargetsFinder).to receive(:new).with(project, user).and_return(finder_mock)
    end

    it 'returns whatever finder returns' do
      is_expected.to eq ['finder_return_value']
    end
  end

  describe '#valid_fork_branch?' do
    subject { service.valid_fork_branch?(branch) }

    context 'when branch exists' do
      let(:branch) { project.default_branch_or_main }

      it { is_expected.to be_truthy }
    end

    context 'when branch does not exist' do
      let(:branch) { 'branch-that-does-not-exist' }

      it { is_expected.to be_falsey }
    end
  end

  describe '#valid_fork_target?' do
    subject { service.valid_fork_target? }

    let(:params) { {} }

    context 'when target is not passed' do
      context 'when current user is an admin' do
        let(:user) { build(:user, :admin) }

        it { is_expected.to be_truthy }
      end

      context 'when current_user is not an admin' do
        let(:user) { create(:user) }

        let(:finder_mock) { instance_double('ForkTargetsFinder', execute: [user.namespace]) }

        before do
          allow(ForkTargetsFinder).to receive(:new).with(project, user).and_return(finder_mock)
        end

        context 'when target namespace is in valid fork targets' do
          let(:params) { { namespace: user.namespace } }

          it { is_expected.to be_truthy }
        end

        context 'when target namespace is not in valid fork targets' do
          let(:params) { { namespace: create(:group) } }

          it { is_expected.to be_falsey }
        end
      end
    end

    context 'when target is passed' do
      subject { service.valid_fork_target?(target) }

      let(:target) { create(:group) }

      context 'when current user is an admin' do
        let(:user) { build(:user, :admin) }

        it { is_expected.to be_truthy }
      end

      context 'when current user is not an admin' do
        let(:user) { create(:user) }

        before do
          allow(ForkTargetsFinder).to receive(:new).with(project, user).and_return(finder_mock)
        end

        context 'when target namespace is in valid fork targets' do
          let(:finder_mock) { instance_double('ForkTargetsFinder', execute: [target]) }

          it { is_expected.to be_truthy }
        end

        context 'when target namespace is not in valid fork targets' do
          let(:finder_mock) { instance_double('ForkTargetsFinder', execute: [create(:group)]) }

          it { is_expected.to be_falsey }
        end
      end
    end
  end
end
