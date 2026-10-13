# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DropUsersStaticObjectTokenIndex, feature_category: :source_code_management do
  let(:connection) { described_class.new.connection }
  let(:index_name) { described_class::INDEX_NAME }

  describe '#up' do
    it 'removes the index' do
      expect { migrate! }.to change {
        connection.index_exists?(:users, :static_object_token, name: index_name)
      }.from(true).to(false)
    end
  end

  describe '#down' do
    it 'restores the unique index', :aggregate_failures do
      migrate!
      schema_migrate_down!

      index = connection.indexes(:users).find { |i| i.name == index_name.to_s }

      expect(index).to be_present
      expect(index.unique).to be(true)
    end
  end
end
