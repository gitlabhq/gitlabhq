require 'spec_helper'

describe Projects::ForkService, services: true do
  let(:gitlab_shell) { Gitlab::Shell.new }
  describe 'fork by user' do
    before do
      @from_user = create(:user)
      @from_namespace = @from_user.namespace
      avatar = fixture_file_upload(Rails.root + "spec/fixtures/dk.png", "image/png")
      @from_project = create(:project,
                             :repository,
                             creator_id: @from_user.id,
                             namespace: @from_namespace,
                             star_count: 107,
                             avatar: avatar,
                             description: 'wow such project')
      @to_user = create(:user)
      @to_namespace = @to_user.namespace
      @from_project.add_user(@to_user, :developer)
    end

    context 'fork project' do
      context 'when forker is a guest' do
        before do
          @guest = create(:user)
          @from_project.add_user(@guest, :guest)
        end
        subject { fork_project(@from_project, @guest) }

        it { is_expected.not_to be_persisted }
        it { expect(subject.errors[:forked_from_project_id]).to eq(['is forbidden']) }
      end

      describe "successfully creates project in the user namespace" do
        let(:to_project) { fork_project(@from_project, @to_user) }

        it { expect(to_project).to be_persisted }
        it { expect(to_project.errors).to be_empty }
        it { expect(to_project.owner).to eq(@to_user) }
        it { expect(to_project.namespace).to eq(@to_user.namespace) }
        it { expect(to_project.star_count).to be_zero }
        it { expect(to_project.description).to eq(@from_project.description) }
        it { expect(to_project.avatar.file).to be_exists }

        # This test is here because we had a bug where the from-project lost its
        # avatar after being forked.
        # https://gitlab.com/gitlab-org/gitlab-ce/issues/26158
        it "after forking the from-project still has its avatar" do
          # If we do not fork the project first we cannot detect the bug.
          expect(to_project).to be_persisted

          expect(@from_project.avatar.file).to be_exists
        end
      end
    end

    context 'project already exists' do
      it "fails due to validation, not transaction failure" do
        @existing_project = create(:project, :repository, creator_id: @to_user.id, name: @from_project.name, namespace: @to_namespace)
        @to_project = fork_project(@from_project, @to_user)
        expect(@existing_project).to be_persisted

        expect(@to_project).not_to be_persisted
        expect(@to_project.errors[:name]).to eq(['has already been taken'])
        expect(@to_project.errors[:path]).to eq(['has already been taken'])
      end
    end

    context 'repository already exists' do
      let(:repository_storage_path) { Gitlab.config.repositories.storages['default']['path'] }

      before do
        gitlab_shell.add_repository(repository_storage_path, "#{@to_user.namespace.full_path}/#{@from_project.path}")
      end

      after do
        gitlab_shell.remove_repository(repository_storage_path, "#{@to_user.namespace.full_path}/#{@from_project.path}")
      end

      it 'does not allow creation' do
        to_project = fork_project(@from_project, @to_user)

        expect(to_project).not_to be_persisted
        expect(to_project.errors.messages).to have_key(:base)
        expect(to_project.errors.messages[:base].first).to match('There is already a repository with that name on disk')
      end
    end

    context 'GitLab CI is enabled' do
      it "forks and enables CI for fork" do
        @from_project.enable_ci
        @to_project = fork_project(@from_project, @to_user)
        expect(@to_project.builds_enabled?).to be_truthy
      end
    end

    context "when project has restricted visibility level" do
      context "and only one visibility level is restricted" do
        before do
          @from_project.update_attributes(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
          stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::INTERNAL])
        end

        it "creates fork with highest allowed level" do
          forked_project = fork_project(@from_project, @to_user)

          expect(forked_project.visibility_level).to eq(Gitlab::VisibilityLevel::PUBLIC)
        end
      end

      context "and all visibility levels are restricted" do
        before do
          stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC, Gitlab::VisibilityLevel::INTERNAL, Gitlab::VisibilityLevel::PRIVATE])
        end

        it "creates fork with private visibility levels" do
          forked_project = fork_project(@from_project, @to_user)

          expect(forked_project.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
        end
      end
    end
  end

  describe 'fork to namespace' do
    before do
      @group_owner = create(:user)
      @developer   = create(:user)
      @project     = create(:project, :repository,
                            creator_id: @group_owner.id,
                            star_count: 777,
                            description: 'Wow, such a cool project!')
      @group = create(:group)
      @group.add_user(@group_owner, GroupMember::OWNER)
      @group.add_user(@developer,   GroupMember::DEVELOPER)
      @project.add_user(@developer,   :developer)
      @project.add_user(@group_owner, :developer)
      @opts = { namespace: @group }
    end

    context 'fork project for group' do
      it 'group owner successfully forks project into the group' do
        to_project = fork_project(@project, @group_owner, @opts)

        expect(to_project).to             be_persisted
        expect(to_project.errors).to      be_empty
        expect(to_project.owner).to       eq(@group)
        expect(to_project.namespace).to   eq(@group)
        expect(to_project.name).to        eq(@project.name)
        expect(to_project.path).to        eq(@project.path)
        expect(to_project.description).to eq(@project.description)
        expect(to_project.star_count).to  be_zero
      end
    end

    context 'fork project for group when user not owner' do
      it 'group developer fails to fork project into the group' do
        to_project = fork_project(@project, @developer, @opts)
        expect(to_project.errors[:namespace]).to eq(['is not valid'])
      end
    end

    context 'project already exists in group' do
      it 'fails due to validation, not transaction failure' do
        existing_project = create(:project, :repository,
                                  name: @project.name,
                                  namespace: @group)
        to_project = fork_project(@project, @group_owner, @opts)
        expect(existing_project.persisted?).to be_truthy
        expect(to_project.errors[:name]).to eq(['has already been taken'])
        expect(to_project.errors[:path]).to eq(['has already been taken'])
      end
    end
  end

  def fork_project(from_project, user, params = {})
    allow(RepositoryForkWorker).to receive(:perform_async).and_return(true)
    Projects::ForkService.new(from_project, user, params).execute
  end
end
