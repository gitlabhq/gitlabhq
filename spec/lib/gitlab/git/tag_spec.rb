require "spec_helper"

describe Gitlab::Git::Tag, seed_helper: true do
  let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '') }

  shared_examples 'Gitlab::Git::Repository#tags' do
    describe 'first tag' do
      let(:tag) { repository.tags.first }

      it { expect(tag.name).to eq("v1.0.0") }
      it { expect(tag.target).to eq("f4e6814c3e4e7a0de82a9e7cd20c626cc963a2f8") }
      it { expect(tag.dereferenced_target.sha).to eq("6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9") }
      it { expect(tag.message).to eq("Release") }
    end

    describe 'last tag' do
      let(:tag) { repository.tags.last }

      it { expect(tag.name).to eq("v1.2.1") }
      it { expect(tag.target).to eq("2ac1f24e253e08135507d0830508febaaccf02ee") }
      it { expect(tag.dereferenced_target.sha).to eq("fa1b1e6c004a68b7d8763b86455da9e6b23e36d6") }
      it { expect(tag.message).to eq("Version 1.2.1") }
    end

    it { expect(repository.tags.size).to eq(SeedRepo::Repo::TAGS.size) }
  end

  context 'when Gitaly tags feature is enabled' do
    it_behaves_like 'Gitlab::Git::Repository#tags'
  end

  context 'when Gitaly tags feature is disabled', :skip_gitaly_mock do
    it_behaves_like 'Gitlab::Git::Repository#tags'
  end
end
