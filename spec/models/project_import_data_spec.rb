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
end
