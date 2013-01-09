require 'spec_helper'

describe "Projects" do
  before { login_as :user }

  describe "DELETE /projects/:id" do
    before do
      @project = create(:project, namespace: @user.namespace)
      @project.team << [@user, :master]
      visit edit_project_path(@project)
    end

    it "should be correct path" do
      expect { click_link "Remove" }.to change {Project.count}.by(-1)
    end
  end
end
