require 'spec_helper'

describe Projects::DestroyService do
  let!(:user) { create(:user) }
  let!(:project) { create(:project, namespace: user.namespace) }
  let!(:path) { project.repository.path_to_repo }
  let!(:remove_path) { path.sub(/\.git\Z/, "+#{project.id}+deleted.git") }

  context 'Sidekiq inline' do
    before do
      # Run sidekiq immediatly to check that renamed repository will be removed
      Sidekiq::Testing.inline! { destroy_project(project, user, {}) }
    end

    it { Project.all.should_not include(project) }
    it { Dir.exists?(path).should be_falsey }
    it { Dir.exists?(remove_path).should be_falsey }
  end

  context 'Sidekiq fake' do
    before do
      # Dont run sidekiq to check if renamed repository exists
      Sidekiq::Testing.fake! { destroy_project(project, user, {}) }
    end

    it { Project.all.should_not include(project) }
    it { Dir.exists?(path).should be_falsey }
    it { Dir.exists?(remove_path).should be_truthy }
  end

  def destroy_project(project, user, params)
    Projects::DestroyService.new(project, user, params).execute
  end
end
