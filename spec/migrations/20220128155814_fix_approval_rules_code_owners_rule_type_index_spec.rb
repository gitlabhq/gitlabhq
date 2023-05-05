# frozen_string_literal: true

require 'spec_helper'
require_migration!('fix_approval_rules_code_owners_rule_type_index')

RSpec.describe FixApprovalRulesCodeOwnersRuleTypeIndex, :migration, feature_category: :source_code_management do
  let(:table_name) { :approval_merge_request_rules }
  let(:index_name) { 'index_approval_rules_code_owners_rule_type' }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(subject.index_exists_by_name?(table_name, index_name)).to be_truthy
      }

      migration.after -> {
        expect(subject.index_exists_by_name?(table_name, index_name)).to be_truthy
      }
    end
  end

  context 'when the index already exists' do
    before do
      subject.add_concurrent_index table_name, :merge_request_id, where: 'rule_type = 2', name: index_name
    end

    it 'keeps the index' do
      migrate!

      expect(subject.index_exists_by_name?(table_name, index_name)).to be_truthy
    end
  end
end
