# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Git::Patches::CommitPatches, feature_category: :source_code_management do
  describe '#commit' do
    let(:patches) do
      patches_folder = Rails.root.join('spec/fixtures/patchfiles')
      content_1 = File.read(File.join(patches_folder, "0001-This-does-not-apply-to-the-feature-branch.patch"))
      content_2 = File.read(File.join(patches_folder, "0001-A-commit-from-a-patch.patch"))

      Gitlab::Git::Patches::Collection.new([content_1, content_2])
    end

    let(:user) { build(:user) }
    let(:branch_name) { 'branch-with-patches' }
    let(:repository) { create(:project, :repository).repository }
    let(:target_sha) { repository.commit(branch_name)&.sha }

    subject(:commit_patches) do
      described_class.new(user, repository, branch_name, patches, target_sha)
    end

    it 'applies the patches' do
      new_rev = commit_patches.commit

      expect(repository.commit(new_rev)).not_to be_nil
    end

    it 'updates the branch cache' do
      expect(repository).to receive(:after_create_branch)

      commit_patches.commit
    end

    context 'when the repository does not exist' do
      let(:repository) { create(:project).repository }

      it 'raises the correct error' do
        expect { commit_patches.commit }.to raise_error(Gitlab::Git::Repository::NoRepository)
      end
    end

    context 'when the patch does not apply' do
      let(:branch_name) { 'feature' }

      it 'raises the correct error' do
        expect { commit_patches.commit }.to raise_error(Gitlab::Git::CommandError)
      end
    end
  end
end
