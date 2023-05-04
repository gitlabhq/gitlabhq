# frozen_string_literal: true

RSpec.shared_examples_for 'value stream analytics event' do
  let(:params) { {} }
  let(:instance) { described_class.new(params) }
  let(:expected_hash_code) { Digest::SHA256.hexdigest(instance.class.identifier.to_s) }

  it { expect(described_class.name).to be_a_kind_of(String) }
  it { expect(described_class.identifier).to be_a_kind_of(Symbol) }
  it { expect(instance.object_type.ancestors).to include(ApplicationRecord) }
  it { expect(instance).to respond_to(:timestamp_projection) }
  it { expect(instance).to respond_to(:html_description) }
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

RSpec.shared_examples_for 'LEFT JOIN-able value stream analytics event' do
  let(:params) { {} }
  let(:instance) { described_class.new(params) }
  let(:record_with_data) { nil }
  let(:record_without_data) { nil }
  let(:scope) { instance.object_type.all }

  let(:records) do
    scope_with_left_join = instance.include_in(scope)
    scope_with_left_join.select(scope.model.arel_table[:id], instance.timestamp_projection.as('timestamp_column_data')).to_a
  end

  it 'can use the event as LEFT JOIN' do
    expected_record_count = record_without_data.nil? ? 1 : 2

    expect(records.count).to eq(expected_record_count)
  end

  context 'when looking at the record with data' do
    subject(:record) { records.to_a.find { |r| r.id == record_with_data.id } }

    it 'contains the timestamp expression' do
      expect(record.timestamp_column_data).not_to eq(nil)
    end
  end

  context 'when looking at the record without data' do
    subject(:record) { records.to_a.find { |r| r.id == record_without_data.id } }

    it 'returns nil for the timestamp expression' do
      expect(record.timestamp_column_data).to eq(nil) if record_without_data
    end
  end
end

RSpec.shared_examples_for 'value stream analytics first assignment event methods' do
  let_it_be(:model1) { create(model_factory) } # rubocop: disable Rails/SaveBang
  let_it_be(:model2) { create(model_factory) } # rubocop: disable Rails/SaveBang

  let_it_be(:assignment_event1) do
    create(event_factory, action: :add, created_at: 3.years.ago, model_factory => model1)
  end

  let_it_be(:assignment_event2) do
    create(event_factory, action: :add, created_at: 2.years.ago, model_factory => model1)
  end

  let_it_be(:unassignment_event1) do
    create(event_factory, action: :remove, created_at: 1.year.ago, model_factory => model1)
  end

  let(:query) { model1.class.where(id: [model1.id, model2.id]) }
  let(:event) { described_class.new({}) }

  describe '#apply_query_customization' do
    subject(:records) { event.apply_query_customization(query).pluck(:id, *event.column_list).to_a }

    it 'looks up the first assignment event timestamp' do
      expect(records).to match_array([[model1.id, be_within(1.second).of(assignment_event1.created_at)]])
    end
  end

  describe '#apply_negated_query_customization' do
    subject(:records) { event.apply_negated_query_customization(query).pluck(:id).to_a }

    it 'returns records where the event has not happened yet' do
      expect(records).to eq([model2.id])
    end
  end

  describe '#include_in' do
    subject(:records) { event.include_in(query).pluck(:id, *event.column_list).to_a }

    it 'returns both records' do
      expect(records).to match_array([
        [model1.id, be_within(1.second).of(assignment_event1.created_at)],
        [model2.id, nil]
      ])
    end

    context 'when invoked multiple times' do
      subject(:records) do
        scope = event.include_in(query)
        event.include_in(scope).pluck(:id, *event.column_list).to_a
      end

      it 'returns both records' do
        expect(records).to match_array([
          [model1.id, be_within(1.second).of(assignment_event1.created_at)],
          [model2.id, nil]
        ])
      end
    end
  end
end
