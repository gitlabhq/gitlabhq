# frozen_string_literal: true

RSpec.shared_examples_for 'value stream analytics event' do
  let(:params) { {} }
  let(:instance) { described_class.new(params) }
  let(:expected_hash_code) { Digest::SHA256.hexdigest(instance.class.identifier.to_s) }

  it { expect(described_class.name).to be_a_kind_of(String) }
  it { expect(described_class.identifier).to be_a_kind_of(Symbol) }
  it { expect(instance.object_type.ancestors).to include(ApplicationRecord) }
  it { expect(instance).to respond_to(:timestamp_projection) }
  it { expect(instance).to respond_to(:markdown_description) }
  it { expect(instance.column_list).to be_a_kind_of(Array) }

  describe '#apply_query_customization' do
    it 'expects an ActiveRecord::Relation object as argument and returns a modified version of it' do
      input_query = instance.object_type.all

      output_query = instance.apply_query_customization(input_query)
      expect(output_query).to be_a_kind_of(ActiveRecord::Relation)
    end
  end

  describe '#hash_code' do
    it 'returns a hash that uniquely identifies an event' do
      expect(instance.hash_code).to eq(expected_hash_code)
    end

    it 'does not differ when the same object is built with the same params' do
      another_instance_with_same_params = described_class.new(params)

      expect(another_instance_with_same_params.hash_code).to eq(instance.hash_code)
    end
  end
end
