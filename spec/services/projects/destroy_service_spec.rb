require 'spec_helper'

describe Projects::DestroyService, services: true do
  let!(:user) { create(:user) }
  let!(:project) { create(:project, namespace: user.namespace) }
  let!(:path) { project.repository.path_to_repo }
  let!(:remove_path) { path.sub(/\.git\Z/, "+#{project.id}+deleted.git") }

  context 'Sidekiq inline' do
    before do
      # Run sidekiq immediatly to check that renamed repository will be removed
      Sidekiq::Testing.inline! { destroy_project(project, user, {}) }
    end

    it { expect(Project.all).not_to include(project) }
    it { expect(Dir.exists?(path)).to be_falsey }
    it { expect(Dir.exists?(remove_path)).to be_falsey }
  end

  context 'Sidekiq fake' do
    before do
      # Dont run sidekiq to check if renamed repository exists
      Sidekiq::Testing.fake! { destroy_project(project, user, {}) }
    end

    it { expect(Project.all).not_to include(project) }
    it { expect(Dir.exists?(path)).to be_falsey }
    it { expect(Dir.exists?(remove_path)).to be_truthy }
  end

  def destroy_project(project, user, params)
    Projects::DestroyService.new(project, user, params).execute
  end
end
