# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaValidation::Runner, feature_category: :database do
  let(:structure_file_path) { Rails.root.join('spec/fixtures/structure.sql') }
  let(:connection) { ActiveRecord::Base.connection }

  let(:database) { Gitlab::Database::SchemaValidation::Database.new(connection) }
  let(:structure_sql) { Gitlab::Database::SchemaValidation::StructureSql.new(structure_file_path) }

  describe '#execute' do
    subject(:inconsistencies) { described_class.new(structure_sql, database).execute }

    it 'returns inconsistencies' do
      expect(inconsistencies).not_to be_empty
    end
  end
end
