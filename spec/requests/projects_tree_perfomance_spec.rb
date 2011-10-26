require 'spec_helper'
require 'benchmark'

describe "Projects" do
  before { login_as :user }

  describe "GET /projects/tree" do
    describe "head" do
      before do
        @project = Factory :project
        @project.add_access(@user, :read)

      end

      it "should be fast" do
        time = Benchmark.realtime do
          visit tree_project_path(@project)
        end
        (time < 1.0).should be_true
      end
    end

    describe ValidCommit::ID do
      before do
        @project = Factory :project
        @project.add_access(@user, :read)
      end

      it "should be fast" do
        time = Benchmark.realtime do
          visit tree_project_path(@project, :commit_id => ValidCommit::ID)
        end
        (time < 1.0).should be_true
      end
    end
  end
end
