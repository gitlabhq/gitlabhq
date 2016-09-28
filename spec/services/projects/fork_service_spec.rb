require 'spec_helper'

describe Projects::ForkService, services: true do
  describe :fork_by_user do
    before do
      @from_namespace = create(:namespace)
      @from_user = create(:user, namespace: @from_namespace )
      @from_project = create(:project,
                             creator_id: @from_user.id,
                             namespace: @from_namespace,
                             star_count: 107,
                             description: 'wow such project')
      @to_namespace = create(:namespace)
      @to_user = create(:user, namespace: @to_namespace)
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
      end
    end

    context 'project already exists' do
      it "should fail due to validation, not transaction failure" do
        @existing_project = create(:project, creator_id: @to_user.id, name: @from_project.name, namespace: @to_namespace)
        @to_project = fork_project(@from_project, @to_user)
        expect(@existing_project).to be_persisted

        expect(@to_project).not_to be_persisted
        expect(@to_project.errors[:name]).to eq(['has already been taken'])
        expect(@to_project.errors[:path]).to eq(['has already been taken'])
      end
    end

    context 'GitLab CI is enabled' do
      it "fork and enable CI for fork" do
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

  describe :fork_to_namespace do
    before do
      @group_owner = create(:user)
      @developer   = create(:user)
      @project     = create(:project, creator_id: @group_owner.id,
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
      it 'group developer should fail to fork project into the group' do
        to_project = fork_project(@project, @developer, @opts)
        expect(to_project.errors[:namespace]).to eq(['is not valid'])
      end
    end

    context 'project already exists in group' do
      it 'should fail due to validation, not transaction failure' do
        existing_project = create(:project, name: @project.name,
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
