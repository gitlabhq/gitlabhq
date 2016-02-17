require 'spec_helper'

describe DeleteUserWorker do
  describe "Deletes a user and all their personal projects" do
    let!(:user)         { create(:user) }
    let!(:current_user) { create(:user) }
    let!(:namespace)    { create(:namespace, owner: user) }
    let!(:project)      { create(:project, namespace: namespace) }

    before do
      DeleteUserWorker.new.perform(current_user.id, user.id)
    end

    it 'deletes all personal projects' do
      expect { Project.find(project.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'deletes the user' do
      expect { User.find(user.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
