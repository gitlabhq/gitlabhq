# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Git::DiffTree, feature_category: :source_code_management do
  subject(:diff_tree) { described_class.new(left_tree_id, right_tree_id) }

  let(:left_tree_id) { '1a0b36b3cdad1d2ee32457c102a8c0b7056fa863' }
  let(:right_tree_id) { '60ecb67744cb56576c30214ff52294f8ce2def98' }

  describe '#left_tree_id' do
    subject { diff_tree.left_tree_id }

    it { is_expected.to eq(left_tree_id) }
  end

  describe '#right_tree_id' do
    subject { diff_tree.right_tree_id }

    it { is_expected.to eq(right_tree_id) }
  end
end
