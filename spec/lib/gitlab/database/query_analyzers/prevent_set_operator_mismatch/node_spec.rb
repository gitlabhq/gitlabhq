# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::QueryAnalyzers::PreventSetOperatorMismatch::Node, feature_category: :cell do
  include PreventSetOperatorMismatchHelper

  let(:sql) { 'SELECT id FROM namespaces' }
  let(:node) { sql_select_node(sql) }

  describe '.descendants' do
    context 'with a block' do
      it do
        nodes = []
        described_class.descendants(node.from_clause) do |node|
          nodes << node.class
        end
        expect(nodes).to match_array [PgQuery::Node, PgQuery::RangeVar]
      end
    end

    context 'without a block' do
      subject { described_class.descendants(node) }

      it { is_expected.to be_instance_of Enumerator }
    end

    context 'with a filter' do
      let(:filter) { ->(field) { %i[from_clause target_list].include?(field) } }

      subject { described_class.descendants(node, filter: filter).count }

      it 'only traverse nodes that match the filter' do
        is_expected.to eq 2
      end
    end
  end

  describe '.locate_descendant' do
    subject { described_class.locate_descendant(node.target_list, :res_target) }

    it { is_expected.to be_instance_of PgQuery::ResTarget }

    context 'with a filter' do
      subject { described_class.locate_descendant(node.target_list, :res_target, filter: ->(_) { false }) }

      it { is_expected.to be_nil }
    end
  end

  describe '.locate_descendants' do
    subject { described_class.locate_descendants(node.target_list, :res_target) }

    it { is_expected.to be_instance_of Array }

    context 'with a filter' do
      subject { described_class.locate_descendant(node.target_list, :res_target, filter: ->(_) { false }) }

      it { is_expected.to be_nil }
    end
  end

  describe '.dig' do
    subject { described_class.dig(node.target_list[0], :res_target, :val, :column_ref) }

    it { is_expected.to be_instance_of PgQuery::ColumnRef }
  end
end
