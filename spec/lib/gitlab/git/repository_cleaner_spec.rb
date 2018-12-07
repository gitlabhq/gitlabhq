require 'spec_helper'

describe Gitlab::Git::RepositoryCleaner do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:head_sha) { repository.head_commit.id }

  let(:object_map) { StringIO.new("#{head_sha} #{'0' * 40}") }

  subject(:cleaner) { described_class.new(repository.raw) }

  describe '#apply_bfg_object_map' do
    it 'removes internal references pointing at SHAs in the object map' do
      # Create some refs we expect to be removed
      repository.keep_around(head_sha)
      repository.create_ref(head_sha, 'refs/environments/1')
      repository.create_ref(head_sha, 'refs/merge-requests/1')
      repository.create_ref(head_sha, 'refs/heads/_keep')
      repository.create_ref(head_sha, 'refs/tags/_keep')

      cleaner.apply_bfg_object_map(object_map)

      aggregate_failures do
        expect(repository.kept_around?(head_sha)).to be_falsy
        expect(repository.ref_exists?('refs/environments/1')).to be_falsy
        expect(repository.ref_exists?('refs/merge-requests/1')).to be_falsy
        expect(repository.ref_exists?('refs/heads/_keep')).to be_truthy
        expect(repository.ref_exists?('refs/tags/_keep')).to be_truthy
      end
    end
  end
end
