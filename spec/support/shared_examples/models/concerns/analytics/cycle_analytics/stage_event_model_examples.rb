# frozen_string_literal: true

RSpec.shared_examples 'StageEventModel' do
  describe '.upsert_data' do
    let(:time) { Time.parse(Time.current.to_s(:db)) } # truncating the timestamp so we can compare it with the timestamp loaded from the DB
    let(:input_data) do
      [
        {
          stage_event_hash_id: 1,
          issuable_id: 2,
          group_id: 3,
          project_id: 4,
          author_id: 5,
          milestone_id: 6,
          start_event_timestamp: time,
          end_event_timestamp: time
        },
        {
          stage_event_hash_id: 7,
          issuable_id: 8,
          group_id: 10,
          project_id: 11,
          author_id: 12,
          milestone_id: 13,
          start_event_timestamp: time,
          end_event_timestamp: time
        }
      ]
    end

    let(:column_order) do
      [
        :stage_event_hash_id,
        described_class.issuable_id_column,
        :group_id,
        :project_id,
        :milestone_id,
        :author_id,
        :start_event_timestamp,
        :end_event_timestamp
      ]
    end

    subject(:upsert_data) { described_class.upsert_data(input_data) }

    it 'inserts the data' do
      upsert_data

      expect(described_class.count).to eq(input_data.count)
    end

    it 'does not produce duplicate rows' do
      2.times { upsert_data }

      expect(described_class.count).to eq(input_data.count)
    end

    it 'inserts the data correctly' do
      upsert_data

      output_data = described_class.all.map do |record|
        column_order.map { |column| record[column] }
      end.sort

      expect(input_data.map(&:values).sort).to eq(output_data)
    end
  end
end
