require 'spec_helper'

describe Projects::ForkService do
  describe :fork_by_user do
    before do
      @from_namespace = create(:namespace)
      @from_user = create(:user, namespace: @from_namespace )
      @from_project = create(:project, creator_id: @from_user.id, namespace: @from_namespace)
      @to_namespace = create(:namespace)
      @to_user = create(:user, namespace: @to_namespace)
    end

    context 'fork project' do

      it "successfully creates project in the user namespace" do
        @to_project = fork_project(@from_project, @to_user)

        expect(@to_project.owner).to eq(@to_user)
        expect(@to_project.namespace).to eq(@to_user.namespace)
      end
    end

    context 'fork project failure' do

      it "fails due to transaction failure" do
        # make the mock gitlab-shell fail
        @to_project = fork_project(@from_project, @to_user, false)

        expect(@to_project.errors).not_to be_empty
        expect(@to_project.errors[:base]).to include("Fork transaction failed.")
      end

    end

    context 'project already exists' do

      it "should fail due to validation, not transaction failure" do
        @existing_project = create(:project, creator_id: @to_user.id, name: @from_project.name, namespace: @to_namespace)
        @to_project = fork_project(@from_project, @to_user)

        expect(@existing_project.persisted?).to be_true
        expect(@to_project.errors[:base]).to include("Invalid fork destination")
        expect(@to_project.errors[:base]).not_to include("Fork transaction failed.")
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
