require 'spec_helper'

describe Geo::RepositoryUpdateService do
  let(:project) { create(:empty_project) }
  let(:clone_url) { project.ssh_url_to_repo }

  subject { described_class.new(project, clone_url) }

  describe '#execute' do
    before do
      allow_any_instance_of(Gitlab::Geo).to receive_messages(secondary?: true)
      allow(project.repository).to receive(:fetch_geo_mirror).and_return(true)
      allow(project).to receive(:repository_exists?) { false }
      allow(project).to receive(:empty_repo?) { true }

      allow(project.repository).to receive(:expire_all_method_caches)
      allow(project.repository).to receive(:expire_branch_cache)
      allow(project.repository).to receive(:expire_content_cache)
    end

    it 'releases the lease' do
      expect(Gitlab::ExclusiveLease).to receive(:cancel).once.and_call_original

      subject.execute
    end

    it 'creates a new repository' do
      expect(project).to receive(:create_repository)

      subject.execute
    end

    it 'executes after_create hook' do
      expect(project.repository).to receive(:after_create).at_least(:once)

      subject.execute
    end

    it 'fetches the Geo mirror' do
      expect(project.repository).to receive(:fetch_geo_mirror)

      subject.execute
    end

    it 'expires repository caches' do
      expect(project.repository).to receive(:expire_all_method_caches)
      expect(project.repository).to receive(:expire_branch_cache)
      expect(project.repository).to receive(:expire_content_cache)

      subject.execute
    end

    it 'rescues Gitlab::Shell::Error failures' do
      expect(project.repository).to receive(:fetch_geo_mirror).and_raise(Gitlab::Shell::Error)

      expect { subject.execute }.not_to raise_error
    end

    it 'rescues Gitlab::Git::Repository::NoRepository failures and fires after_create hook' do
      expect(project.repository).to receive(:fetch_geo_mirror).and_raise(Gitlab::Git::Repository::NoRepository)
      expect_any_instance_of(Repository).to receive(:after_create)

      expect { subject.execute }.not_to raise_error
    end
  end
end
