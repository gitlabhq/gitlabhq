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

  def fork_project(from_project, user, fork_success = true)
    context = Projects::ForkService.new(from_project, user)
    shell = double("gitlab_shell")
    shell.stub(fork_repository: fork_success)
    context.stub(gitlab_shell: shell)
    context.execute
  end
end
