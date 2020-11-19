# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Common::Transformers::GraphqlCleanerTransformer do
  describe '#transform' do
    let_it_be(:expected_output) do
      {
        'name' => 'test',
        'fullName' => 'test',
        'description' => 'test',
        'labels' => [
          { 'title' => 'label1' },
          { 'title' => 'label2' },
          { 'title' => 'label3' }
        ]
      }
    end

    it 'deep cleans hash from GraphQL keys' do
      data = {
        'data' => {
          'group' => {
            'name' => 'test',
            'fullName' => 'test',
            'description' => 'test',
            'labels' => {
              'edges' => [
                { 'node' => { 'title' => 'label1' } },
                { 'node' => { 'title' => 'label2' } },
                { 'node' => { 'title' => 'label3' } }
              ]
            }
          }
        }
      }

      transformed_data = described_class.new.transform(nil, data)

      expect(transformed_data).to eq(expected_output)
    end

    context 'when data does not have data/group nesting' do
      it 'deep cleans hash from GraphQL keys' do
        data = {
          'name' => 'test',
          'fullName' => 'test',
          'description' => 'test',
          'labels' => {
            'edges' => [
              { 'node' => { 'title' => 'label1' } },
              { 'node' => { 'title' => 'label2' } },
              { 'node' => { 'title' => 'label3' } }
            ]
          }
        }

        transformed_data = described_class.new.transform(nil, data)

        expect(transformed_data).to eq(expected_output)
      end
    end

    context 'when data is not a hash' do
      it 'does not perform transformation' do
        data = 'test'

        transformed_data = described_class.new.transform(nil, data)

        expect(transformed_data).to eq(data)
      end
    end

    context 'when nested data is not an array or hash' do
      it 'only removes top level data/group keys' do
        data = {
          'data' => {
            'group' => 'test'
          }
        }

        transformed_data = described_class.new.transform(nil, data)

        expect(transformed_data).to eq('test')
      end
    end
  end
end
