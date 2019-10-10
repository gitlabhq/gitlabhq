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

    context 'disallows default stage names when creating custom stage' do
      let(:invalid_params) { valid_params.merge(name: Gitlab::Analytics::CycleAnalytics::DefaultStages.names.first, custom: true) }
      let(:stage) { described_class.new(invalid_params) }

      it { expect(stage).not_to be_valid }
    end
  end

  describe '#subject_class' do
    it 'infers the model from the start event' do
      stage = described_class.new(valid_params)

      expect(stage.subject_class).to eq(MergeRequest)
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

  describe '#matches_with_stage_params?' do
    let(:params) { Gitlab::Analytics::CycleAnalytics::DefaultStages.params_for_test_stage }

    it 'matches with default stage params' do
      stage = described_class.new(params)

      expect(stage).to be_default_stage
      expect(stage).to be_matches_with_stage_params(params)
    end

    it "mismatches when the stage is custom" do
      stage = described_class.new(params.merge(custom: true))

      expect(stage).not_to be_default_stage
      expect(stage).not_to be_matches_with_stage_params(params)
    end
  end

  describe '#parent_id' do
    it "delegates to 'parent_name'_id attribute" do
      stage = described_class.new(parent: parent)

      expect(stage.parent_id).to eq(parent.id)
    end
  end
end
