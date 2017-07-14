require 'spec_helper'

describe Sortable do
  shared_examples 'sorts when appropriate' do
    describe '#where' do
      it 'orders by id, descending' do
        order_node = relation.where(iid: 1).order_values.first
        expect(order_node).to be_a(Arel::Nodes::Descending)
        expect(order_node.expr.name).to eq(:id)
      end
    end

    describe '#find_by' do
      it 'does not order' do
        expect(relation).to receive(:unscope).with(:order).and_call_original

        relation.find_by(iid: 1)
      end
    end
  end

  describe 'on the root relation' do
    let(:relation) { Issue.all }

    it_behaves_like 'sorts when appropriate'
  end

  describe 'on an association collection' do
    let(:project) { create(:project) }
    let(:relation) { project.issues.all }

    it_behaves_like 'sorts when appropriate'
  end
end
