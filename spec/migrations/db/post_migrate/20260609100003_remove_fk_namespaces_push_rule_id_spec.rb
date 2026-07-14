# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveFkNamespacesPushRuleId, feature_category: :source_code_management do
  let(:connection) { described_class.new.connection }
  let(:foreign_key_name) { described_class::FOREIGN_KEY_NAME }

  describe '#up', :aggregate_failures do
    it 'removes the foreign key' do
      expect { migrate! }.to change {
        connection.foreign_keys(:namespaces).any? { |fk| fk.name == foreign_key_name }
      }.from(true).to(false)
    end
  end

  describe '#down', :aggregate_failures do
    it 'restores the foreign key' do
      migrate!
      schema_migrate_down!

      fk = connection.foreign_keys(:namespaces).find { |f| f.name == foreign_key_name }

      expect(fk).to be_present
      expect(fk.column).to eq('push_rule_id')
      expect(fk.to_table).to eq('push_rules')
      expect(fk.on_delete).to eq(:nullify)
    end
  end
end
