# frozen_string_literal: true

shared_examples_for 'cycle analytics event' do
  let(:params) { {} }
  let(:instance) { described_class.new(params) }

  it { expect(described_class.name).to be_a_kind_of(String) }
  it { expect(described_class.identifier).to be_a_kind_of(Symbol) }
  it { expect(instance.object_type.ancestors).to include(ApplicationRecord) }
  it { expect(instance).to respond_to(:timestamp_projection) }

  describe '#apply_query_customization' do
    it 'expects an ActiveRecord::Relation object as argument and returns a modified version of it' do
      input_query = instance.object_type.all

      output_query = instance.apply_query_customization(input_query)
      expect(output_query).to be_a_kind_of(ActiveRecord::Relation)
    end
  end
end
