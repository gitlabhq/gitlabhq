# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaValidation::SchemaObjects::Table, feature_category: :database do
  subject(:table) { described_class.new(name) }

  let(:name) { 'my_table' }

  describe '#name' do
    it { expect(table.name).to eq('my_table') }
  end

  describe '#table_name' do
    it { expect(table.table_name).to eq('my_table') }
  end
end
