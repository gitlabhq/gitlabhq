# frozen_string_literal: true

shared_examples_for 'cycle analytics stage' do
  let(:valid_params) do
    {
      name: 'My Stage',
      parent: parent,
      start_event_identifier: :merge_request_created,
      end_event_identifier: :merge_request_merged
    }
  end

  describe 'validation' do
    it 'is valid' do
      expect(described_class.new(valid_params)).to be_valid
    end

    it 'validates presence of parent' do
      stage = described_class.new(valid_params.except(:parent))

      expect(stage).not_to be_valid
      expect(stage.errors.details[parent_name]).to eq([{ error: :blank }])
    end

    it 'validates presence of start_event_identifier' do
      stage = described_class.new(valid_params.except(:start_event_identifier))

      expect(stage).not_to be_valid
      expect(stage.errors.details[:start_event_identifier]).to eq([{ error: :blank }])
    end

    it 'validates presence of end_event_identifier' do
      stage = described_class.new(valid_params.except(:end_event_identifier))

      expect(stage).not_to be_valid
      expect(stage.errors.details[:end_event_identifier]).to eq([{ error: :blank }])
    end

    it 'is invalid when end_event is not allowed for the given start_event' do
      invalid_params = valid_params.merge(
        start_event_identifier: :merge_request_merged,
        end_event_identifier: :merge_request_created
      )
      stage = described_class.new(invalid_params)

      expect(stage).not_to be_valid
      expect(stage.errors.details[:end_event]).to eq([{ error: :not_allowed_for_the_given_start_event }])
    end
  end

  describe '#subject_model' do
    it 'infers the model from the start event' do
      stage = described_class.new(valid_params)

      expect(stage.subject_model).to eq(MergeRequest)
    end
  end

  describe '#start_event' do
    it 'builds start_event object based on start_event_identifier' do
      stage = described_class.new(start_event_identifier: 'merge_request_created')

      expect(stage.start_event).to be_a_kind_of(Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestCreated)
    end
  end

  describe '#end_event' do
    it 'builds end_event object based on end_event_identifier' do
      stage = described_class.new(end_event_identifier: 'merge_request_merged')

      expect(stage.end_event).to be_a_kind_of(Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestMerged)
    end
  end
end
