# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Git::DiffTree, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:repository) { project.repository }

  describe '.from_commit' do
    subject(:diff_tree) { described_class.from_commit(commit) }

    context 'when commit is an initial commit' do
      let(:commit) { repository.commit('1a0b36b3cdad1d2ee32457c102a8c0b7056fa863') }

      it 'returns the expected diff tree object' do
        expect(diff_tree.left_tree_id).to eq(Gitlab::Git::EMPTY_TREE_ID)
        expect(diff_tree.right_tree_id).to eq(commit.tree_id)
      end
    end

    context 'when commit is a regular commit' do
      let(:commit) { repository.commit('60ecb67744cb56576c30214ff52294f8ce2def98') }

      it 'returns the expected diff tree object' do
        expect(diff_tree.left_tree_id).to eq(commit.parent.tree_id)
        expect(diff_tree.right_tree_id).to eq(commit.tree_id)
      end
    end
  end
end
