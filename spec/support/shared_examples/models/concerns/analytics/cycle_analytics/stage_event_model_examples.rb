# frozen_string_literal: true

RSpec.shared_examples 'StageEventModel' do
  describe '.upsert_data' do
    let(:time) { Time.parse(Time.current.to_fs(:db)) } # truncating the timestamp so we can compare it with the timestamp loaded from the DB
    let(:input_data) do
      [
        {
          stage_event_hash_id: 1,
          issuable_id: 2,
          group_id: 3,
          project_id: 4,
          author_id: 5,
          milestone_id: 6,
          state_id: 1,
          start_event_timestamp: time,
          end_event_timestamp: time,
          duration_in_milliseconds: 3
        },
        {
          stage_event_hash_id: 7,
          issuable_id: 8,
          group_id: 10,
          project_id: 11,
          author_id: 12,
          milestone_id: 13,
          state_id: 1,
          start_event_timestamp: time,
          end_event_timestamp: time,
          duration_in_milliseconds: 5
        }
      ]
    end

    let(:column_order) do
      [
        :stage_event_hash_id,
        described_class.issuable_id_column,
        :group_id,
        :project_id,
        :author_id,
        :milestone_id,
        :state_id,
        :start_event_timestamp,
        :end_event_timestamp,
        :duration_in_milliseconds
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
        column_order.map do |column|
          if column == :state_id
            described_class.states[record[column]]
          else
            record[column]
          end
        end
      end.sort

      expect(input_data.map(&:values).sort).to eq(output_data)
    end
  end

  describe 'scopes' do
    def attributes(array)
      array.map(&:attributes)
    end

    RSpec::Matchers.define :match_attributes do |expected|
      match do |actual|
        actual.map(&:attributes) == expected.map(&:attributes)
      end
    end

    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:user) }
    let_it_be(:milestone) { create(:milestone) }
    let_it_be(:issuable_with_assignee) { create(issuable_factory, assignees: [user]) }

    let_it_be(:record) { create(stage_event_factory, start_event_timestamp: 3.years.ago.to_date, end_event_timestamp: 2.years.ago.to_date) }
    let_it_be(:record_with_author) { create(stage_event_factory, author_id: user.id) }
    let_it_be(:record_with_project) { create(stage_event_factory, project_id: project.id) }
    let_it_be(:record_with_group) { create(stage_event_factory, group_id: project.namespace_id) }
    let_it_be(:record_with_assigned_issuable) { create(stage_event_factory, described_class.issuable_id_column => issuable_with_assignee.id) }
    let_it_be(:record_with_milestone) { create(stage_event_factory, milestone_id: milestone.id) }

    it 'filters by stage_event_hash_id' do
      records = described_class.by_stage_event_hash_id(record.stage_event_hash_id)

      expect(records).to match_attributes([record])
    end

    it 'filters by project_id' do
      records = described_class.by_project_id(project.id)

      expect(records).to match_attributes([record_with_project])
    end

    it 'filters by group_id' do
      records = described_class.by_group_id(project.namespace_id)

      expect(records).to match_attributes([record_with_group])
    end

    it 'filters by author_id' do
      records = described_class.authored(user)

      expect(records).to match_attributes([record_with_author])
    end

    it 'filters by assignee' do
      records = described_class.assigned_to(user)

      expect(records).to match_attributes([record_with_assigned_issuable])
    end

    it 'filters by milestone_id' do
      records = described_class.with_milestone_id(milestone.id)

      expect(records).to match_attributes([record_with_milestone])
    end

    describe 'start_event_timestamp filtering' do
      it 'when range is given' do
        records = described_class
          .start_event_timestamp_after(4.years.ago)
          .start_event_timestamp_before(2.years.ago)

        expect(records).to match_attributes([record])
      end

      it 'when specifying upper bound' do
        records = described_class.start_event_timestamp_before(2.years.ago)

        expect(attributes(records)).to include(attributes([record]).first)
      end

      it 'when specifying the lower bound' do
        records = described_class.start_event_timestamp_after(4.years.ago)

        expect(attributes(records)).to include(attributes([record]).first)
      end
    end

    describe 'end_event_timestamp filtering' do
      it 'when range is given' do
        records = described_class
          .end_event_timestamp_after(3.years.ago)
          .end_event_timestamp_before(1.year.ago)

        expect(records).to match_attributes([record])
      end

      it 'when specifying upper bound' do
        records = described_class.end_event_timestamp_before(1.year.ago)

        expect(attributes(records)).to include(attributes([record]).first)
      end

      it 'when specifying the lower bound' do
        records = described_class.end_event_timestamp_after(3.years.ago)

        expect(attributes(records)).to include(attributes([record]).first)
      end
    end
  end

  describe '#total_time' do
    it 'calcualtes total time from the start_event_timestamp and end_event_timestamp columns' do
      model = build(stage_event_factory, start_event_timestamp: Time.new(2022, 1, 1, 12, 5, 0), end_event_timestamp: Time.new(2022, 1, 1, 12, 6, 30))

      expect(model.total_time).to eq(90)
    end
  end
end
