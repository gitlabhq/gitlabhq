# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespace::TraversalHierarchy, type: :model do
  let_it_be(:root, reload: true) { create(:namespace, :with_hierarchy) }

  describe '.for_namespace' do
    let(:hierarchy) { described_class.for_namespace(namespace) }

    context 'with root group' do
      let(:namespace) { root }

      it { expect(hierarchy.root).to eq root }
    end

    context 'with child group' do
      let(:namespace) { root.children.first.children.first }

      it { expect(hierarchy.root).to eq root }
    end

    context 'with group outside of hierarchy' do
      let(:namespace) { create(:namespace) }

      it { expect(hierarchy.root).not_to eq root }
    end
  end

  describe '.new' do
    let(:hierarchy) { described_class.new(namespace) }

    context 'with root group' do
      let(:namespace) { root }

      it { expect(hierarchy.root).to eq root }
    end

    context 'with child group' do
      let(:namespace) { root.children.first }

      it { expect { hierarchy }.to raise_error(StandardError, 'Must specify a root node') }
    end
  end

  describe '#incorrect_traversal_ids' do
    subject { described_class.new(root).incorrect_traversal_ids }

    it { is_expected.to match_array Namespace.all }
  end

  describe '#sync_traversal_ids!' do
    let(:hierarchy) { described_class.new(root) }

    before do
      hierarchy.sync_traversal_ids!
      root.reload
    end

    it_behaves_like 'hierarchy with traversal_ids'
    it { expect(hierarchy.incorrect_traversal_ids).to be_empty }
  end
end
