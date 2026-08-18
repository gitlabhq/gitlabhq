# frozen_string_literal: true

RSpec.shared_examples 'custom attribute key lookup behavior' do |resource_type|
  let_it_be(:resource) { create(:"#{resource_type}") }

  let_it_be(:matching_custom_attribute) do
    create(:"#{resource_type}_custom_attribute", key: 'test_key', resource_type => resource)
  end

  let_it_be(:other_custom_attribute) do
    create(:"#{resource_type}_custom_attribute", resource_type => resource)
  end

  describe 'scopes' do
    describe '.by_key' do
      using RSpec::Parameterized::TableSyntax

      subject(:custom_attributes) { described_class.by_key(key) }

      where(:key, :match_count) do
        'test_key'              | 1
        'non_existing_test_key' | 0
        nil                     | 0
        ''                      | 0
      end

      with_them do
        it 'returns expected results' do
          expect(custom_attributes.count).to eq(match_count)
        end
      end
    end
  end

  describe '.find_or_initialize_by_key' do
    context 'when record already exists with the given key' do
      it 'returns the existing custom attribute', :aggregate_failures do
        custom_attribute = resource.custom_attributes.find_or_initialize_by_key('test_key')

        expect(custom_attribute).to be_persisted
        expect(custom_attribute.key).to eq('test_key')
        expect(custom_attribute.public_send(resource_type)).to eq(resource)
      end
    end

    context 'when record does not exist with the given key' do
      it 'initializes a new custom attribute with the key', :aggregate_failures do
        custom_attribute = resource.custom_attributes.find_or_initialize_by_key('new_key')

        expect(custom_attribute).not_to be_persisted
        expect(custom_attribute.key).to eq('new_key')
        expect(custom_attribute.public_send(resource_type)).to eq(resource)
      end
    end
  end
end
