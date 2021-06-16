# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddPartialIndexToCiBuildsTableOnUserIdName do
  let(:migration) { described_class.new }

  describe '#up' do
    it 'creates temporary partial index on type' do
      expect { migration.up }.to change { migration.index_exists?(:ci_builds, [:user_id, :name], name: described_class::INDEX_NAME) }.from(false).to(true)
    end
  end

  describe '#down' do
    it 'removes temporary partial index on type' do
      migration.up

      expect { migration.down }.to change { migration.index_exists?(:ci_builds, [:user_id, :name], name: described_class::INDEX_NAME) }.from(true).to(false)
    end
  end
end
