# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::QueryAnalyzers::PreventSetOperatorMismatch::Targets, feature_category: :cell do
  include PreventSetOperatorMismatchHelper

  let(:node) { sql_select_node(sql) }
  let(:select_stmt) { Gitlab::Database::QueryAnalyzers::PreventSetOperatorMismatch::SelectStmt.new(node) }
  let(:target) { node.target_list[0].res_target }

  describe '.reference_names' do
    subject { described_class.reference_names(target, select_stmt) }

    context 'with a literal target' do
      let(:sql) { 'SELECT 1' }

      it { is_expected.to be_empty }
    end

    context 'with a function target' do
      let(:sql) { 'SELECT unnest(ARRAY[1,2]) FROM namespaces, users' }

      it { is_expected.to be_empty }
    end

    context 'with a subselect target' do
      let(:sql) { 'SELECT (SELECT 1) xyz FROM namespaces' }

      it { is_expected.to eq(%w[xyz_subselect]) }

      it 'updates all_references in the select statement' do
        expect { subject }.to change { select_stmt.all_references }
                          .to include('xyz_subselect')
      end
    end

    context 'with an unqualified column name' do
      let(:sql) { 'SELECT id FROM namespaces, users' }

      it { is_expected.to eq(%w[namespaces users]) }
    end

    context 'with a qualified column name' do
      let(:sql) { 'SELECT namespaces.id FROM namespaces, users' }

      it { is_expected.to eq(%w[namespaces]) }
    end

    context 'with a table name' do
      let(:sql) { 'SELECT namespaces FROM namespaces, users' }

      it { is_expected.to eq(%w[namespaces]) }
    end

    context 'with a *' do
      let(:sql) { 'SELECT * FROM namespaces, users' }

      it { is_expected.to eq(%w[namespaces users]) }
    end
  end

  describe '.a_star?' do
    subject { described_class.a_star?(target) }

    context 'when * is used' do
      let(:sql) { 'SELECT * FROM namespaces' }

      it { is_expected.to be_truthy }
    end

    context 'when no * is used' do
      let(:sql) { 'SELECT 1' }

      it { is_expected.to be_falsey }
    end
  end

  describe '.null?' do
    subject { described_class.null?(target) }

    context 'when target is null' do
      let(:sql) { 'SELECT NULL::namespaces FROM namespaces' }

      it { is_expected.to be_truthy }
    end

    context 'when target is not null' do
      let(:sql) { 'SELECT 1' }

      it { is_expected.to be_falsey }
    end
  end
end
