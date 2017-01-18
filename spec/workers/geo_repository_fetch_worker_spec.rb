require 'spec_helper'

describe GeoRepositoryFetchWorker do
  describe '#perform' do
    let(:project) { create(:empty_project) }

    before do
      allow_any_instance_of(Gitlab::Geo).to receive_messages(secondary?: true)
      allow_any_instance_of(Repository).to receive(:fetch_geo_mirror).and_return(true)
      allow_any_instance_of(Project).to receive(:repository_exists?) { false }
      allow_any_instance_of(Project).to receive(:empty_repo?) { true }

      allow_any_instance_of(Repository).to receive(:expire_all_method_caches)
      allow_any_instance_of(Repository).to receive(:expire_branch_cache)
      allow_any_instance_of(Repository).to receive(:expire_content_cache)
    end

    it 'creates a new repository' do
      expect_any_instance_of(Project).to receive(:create_repository)

      perform
    end

    it 'executes after_create hook' do
      expect_any_instance_of(Repository).to receive(:after_create).at_least(:once)

      perform
    end

    it 'fetches the Geo mirror' do
      expect_any_instance_of(Repository).to receive(:fetch_geo_mirror)

      perform
    end

    it 'expires repository caches' do
      expect_any_instance_of(Repository).to receive(:expire_all_method_caches)
      expect_any_instance_of(Repository).to receive(:expire_branch_cache)
      expect_any_instance_of(Repository).to receive(:expire_content_cache)

      perform
    end
  end

  def perform
    subject.perform(project.id, project.ssh_url_to_repo)
  end
end
