# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Common::Transformers::UnderscorifyKeysTransformer do
  describe '#transform' do
    it 'deep underscorifies hash keys' do
      data = {
        'fullPath' => 'Foo',
        'snakeKeys' => {
          'snakeCaseKey' => 'Bar',
          'moreKeys' => {
            'anotherSnakeCaseKey' => 'Test'
          }
        }
      }

      transformed_data = described_class.new.transform(nil, data)

      expect(transformed_data).to have_key('full_path')
      expect(transformed_data).to have_key('snake_keys')
      expect(transformed_data['snake_keys']).to have_key('snake_case_key')
      expect(transformed_data['snake_keys']).to have_key('more_keys')
      expect(transformed_data.dig('snake_keys', 'more_keys')).to have_key('another_snake_case_key')
    end
  end
end
