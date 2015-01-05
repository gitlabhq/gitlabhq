require 'spec_helper'

describe Projects::ForkService do
  describe :fork_by_user do
    before do
      @from_namespace = create(:namespace)
      @from_user = create(:user, namespace: @from_namespace )
      @from_project = create(:project, creator_id: @from_user.id,
                             namespace: @from_namespace, star_count: 107,
                             description: 'wow such project')
      @to_namespace = create(:namespace)
      @to_user = create(:user, namespace: @to_namespace)
    end

    context 'fork project' do
      describe "successfully creates project in the user namespace" do
        let(:to_project) { fork_project(@from_project, @to_user) }

        it { to_project.owner.should == @to_user }
        it { to_project.namespace.should == @to_user.namespace }
        it { to_project.star_count.should be_zero }
        it { to_project.description.should == @from_project.description }
      end
    end

    context 'fork project failure' do
      it "fails due to transaction failure" do
        @to_project = fork_project(@from_project, @to_user, false)
        @to_project.errors.should_not be_empty
        @to_project.errors[:base].should include("Fork transaction failed.")
      end
    end

    context 'project already exists' do
      it "should fail due to validation, not transaction failure" do
        @existing_project = create(:project, creator_id: @to_user.id, name: @from_project.name, namespace: @to_namespace)
        @to_project = fork_project(@from_project, @to_user)
        @existing_project.persisted?.should be_true
        @to_project.errors[:base].should include("Invalid fork destination")
        @to_project.errors[:base].should_not include("Fork transaction failed.")
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
      @opts = { namespace: @group }
    end

    context 'fork project for group' do
      it 'group owner successfully forks project into the group' do
        to_project = fork_project(@project, @group_owner, true, @opts)
        to_project.owner.should       == @group
        to_project.namespace.should   == @group
        to_project.name.should        == @project.name
        to_project.path.should        == @project.path
        to_project.description.should == @project.description
        to_project.star_count.should     be_zero
      end
    end

    context 'fork project for group when user not owner' do
      it 'group developer should fail to fork project into the group' do
        to_project = fork_project(@project, @developer, true, @opts)
        to_project.errors[:namespace].should == ['insufficient access rights']
      end
    end

    context 'project already exists in group' do
      it 'should fail due to validation, not transaction failure' do
        existing_project = create(:project, name: @project.name,
                                            namespace: @group)
        to_project = fork_project(@project, @group_owner, true, @opts)
        existing_project.persisted?.should be_true
        to_project.errors[:base].should == ['Invalid fork destination']
        to_project.errors[:name].should == ['has already been taken']
        to_project.errors[:path].should == ['has already been taken']
      end
    end
  end

  def fork_project(from_project, user, fork_success = true, params = {})
    context = Projects::ForkService.new(from_project, user, params)
    shell = double('gitlab_shell').stub(fork_repository: fork_success)
    context.stub(gitlab_shell: shell)
    context.execute
  end
end
