require 'spec_helper'

describe GeoRepositoryDestroyWorker do
  let!(:project) { create :project_empty_repo }
  let!(:path) { project.repository.path_with_namespace }
  let!(:remove_path) { path.sub(/\.git\Z/, "+#{project.id}+deleted.git") }
  let(:perform!) { subject.perform(project.id, project.name, path) }

  before do
    project.delete
  end

  it 'delegates project removal to Projects::DestroyService' do
    expect_any_instance_of(::Projects::DestroyService).to receive(:geo_replicate)

    perform!
  end

  context 'sidekiq execution' do
    it 'removes the repository from disk' do
      expect(project.gitlab_shell.exists?(project.repository_storage_path, path + '.git')).to be_truthy

      Sidekiq::Testing.inline! { perform! }

      expect(project.gitlab_shell.exists?(project.repository_storage_path, path + '.git')).to be_falsey
      expect(project.gitlab_shell.exists?(project.repository_storage_path, remove_path + '.git')).to be_falsey
    end
  end
end
