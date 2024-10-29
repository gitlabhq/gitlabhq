# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectImportData do
  describe '#merge_data' do
    it 'writes the Hash to the attribute if it is nil' do
      row = described_class.new

      row.merge_data('number' => 10)

      expect(row.data).to eq({ 'number' => 10 })
    end

    it 'merges the Hash into an existing Hash if one was present' do
      row = described_class.new(data: { 'number' => 10 })

      row.merge_data('foo' => 'bar')

      expect(row.data).to eq({ 'number' => 10, 'foo' => 'bar' })
    end
  end

  describe '#merge_credentials' do
    it 'writes the Hash to the attribute if it is nil' do
      row = described_class.new

      row.merge_credentials('number' => 10)

      expect(row.credentials).to eq({ 'number' => 10 })
    end

    it 'merges the Hash into an existing Hash if one was present' do
      row = described_class.new

      row.credentials = { 'number' => 10 }
      row.merge_credentials('foo' => 'bar')

      expect(row.credentials).to eq({ 'number' => 10, 'foo' => 'bar' })
    end
  end

  describe '#clear_credentials' do
    it 'clears out the Hash' do
      row = described_class.new

      row.merge_credentials('number' => 10)
      row.clear_credentials

      expect(row.credentials).to eq({})
    end
  end

  describe '#user_mapping_enabled?' do
    it 'returns user_contribution_mapping_enabled when present in data' do
      import_data = described_class.new(data: { 'user_contribution_mapping_enabled' => true })

      expect(import_data.user_mapping_enabled?).to be(true)
    end

    it 'returns false when user_contribution_mapping_enabled is not present in data' do
      import_data = described_class.new(data: { 'number' => 10 })

      expect(import_data.user_mapping_enabled?).to be(false)
    end

    it 'returns false when data is nil' do
      import_data = described_class.new

      expect(import_data.user_mapping_enabled?).to be(false)
    end
  end
end
