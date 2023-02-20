# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExportCsv::MapExportFieldsService, feature_category: :team_planning do
  let(:selected_fields) { ['Title', 'Author username', 'state'] }
  let(:invalid_fields) { ['Title', 'Author Username', 'State', 'Invalid Field', 'Other Field'] }
  let(:data) do
    {
      'Requirement ID' => '1',
      'Title' => 'foo',
      'Description' => 'bar',
      'Author' => 'root',
      'Author Username' => 'admin',
      'Created At (UTC)' => '2023-02-01 15:16:35',
      'State' => 'opened',
      'State Updated At (UTC)' => '2023-02-01 15:16:35'
    }
  end

  describe '#execute' do
    it 'returns a hash with selected fields only' do
      result = described_class.new(selected_fields, data).execute

      expect(result).to be_a(Hash)
      expect(result.keys).to match_array(selected_fields.map(&:titleize))
    end

    context 'when the fields collection is empty' do
      it 'returns a hash with all fields' do
        result = described_class.new([], data).execute

        expect(result).to be_a(Hash)
        expect(result.keys).to match_array(data.keys)
      end
    end

    context 'when fields collection includes invalid fields' do
      it 'returns a hash with valid selected fields only' do
        result = described_class.new(invalid_fields, data).execute

        expect(result).to be_a(Hash)
        expect(result.keys).to eq(selected_fields.map(&:titleize))
      end
    end
  end

  describe '#invalid_fields' do
    it 'returns an array containing invalid fields' do
      result = described_class.new(invalid_fields, data).invalid_fields

      expect(result).to match_array(['Invalid Field', 'Other Field'])
    end
  end
end
