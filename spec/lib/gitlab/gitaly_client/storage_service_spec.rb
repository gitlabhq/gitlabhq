require 'spec_helper'

describe Gitlab::GitalyClient::StorageService do
  describe '#delete_all_repositories' do
    let!(:project) { create(:project, :repository) }

    it 'removes all repositories' do
      described_class.new(project.repository_storage).delete_all_repositories

      expect(project.repository.exists?).to be(false)
    end
  end
end
