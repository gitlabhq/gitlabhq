# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::TablesSortedByForeignKeys do
  let(:connection) { ApplicationRecord.connection }
  let(:tables) { %w[_test_gitlab_main_items _test_gitlab_main_references] }

  subject do
    described_class.new(connection, tables).execute
  end

  before do
    statement = <<~SQL
      CREATE TABLE _test_gitlab_main_items (id serial NOT NULL PRIMARY KEY);

      CREATE TABLE _test_gitlab_main_references (
        id serial NOT NULL PRIMARY KEY,
        item_id BIGINT NOT NULL,
        CONSTRAINT fk_constrained_1 FOREIGN KEY(item_id) REFERENCES _test_gitlab_main_items(id)
      );
    SQL
    connection.execute(statement)
  end

  describe '#execute' do
    it 'returns the tables sorted by the foreign keys dependency' do
      expect(subject).to eq([['_test_gitlab_main_references'], ['_test_gitlab_main_items']])
    end

    it 'returns both tables together if they are strongly connected' do
      statement = <<~SQL
        ALTER TABLE _test_gitlab_main_items ADD COLUMN reference_id BIGINT
        REFERENCES _test_gitlab_main_references(id)
      SQL
      connection.execute(statement)

      expect(subject).to eq([tables])
    end
  end
end
