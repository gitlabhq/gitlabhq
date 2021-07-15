# frozen_string_literal: true

RSpec.shared_examples 'value stream analytics stage' do
  let(:valid_params) do
    {
      name: 'My Stage',
      parent: parent,
      start_event_identifier: :merge_request_created,
      end_event_identifier: :merge_request_merged
    }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:end_event_label) }
    it { is_expected.to belong_to(:start_event_label) }
  end

  describe 'validation' do
    it 'is valid' do
      expect(described_class.new(valid_params)).to be_valid
    end

    it 'validates presence of parent' do
      stage = described_class.new(valid_params.except(:parent))

      expect(stage).to be_invalid
      expect(stage.errors[parent_name]).to include("can't be blank")
    end

    it 'validates presence of start_event_identifier' do
      stage = described_class.new(valid_params.except(:start_event_identifier))

      expect(stage).to be_invalid
      expect(stage.errors[:start_event_identifier]).to include("can't be blank")
    end

    it 'validates presence of end_event_identifier' do
      stage = described_class.new(valid_params.except(:end_event_identifier))

      expect(stage).to be_invalid
      expect(stage.errors[:end_event_identifier]).to include("can't be blank")
    end

    it 'is invalid when end_event is not allowed for the given start_event' do
      invalid_params = valid_params.merge(
        start_event_identifier: :merge_request_merged,
        end_event_identifier: :merge_request_created
      )
      stage = described_class.new(invalid_params)

      expect(stage).to be_invalid
      expect(stage.errors[:end_event]).to include(s_('CycleAnalytics|not allowed for the given start event'))
    end

    context 'disallows default stage names when creating custom stage' do
      let(:invalid_params) { valid_params.merge(name: Gitlab::Analytics::CycleAnalytics::DefaultStages.names.first, custom: true) }
      let(:stage) { described_class.new(invalid_params) }

      it { expect(stage).not_to be_valid }
    end

    # rubocop: disable Rails/SaveBang
    describe '.by_value_stream' do
      it 'finds stages by value stream' do
        stage1 = create(factory)
        create(factory) # other stage with different value stream

        result = described_class.by_value_stream(stage1.value_stream)

        expect(result).to eq([stage1])
      end
    end
    # rubocop: enable Rails/SaveBang
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

  describe '#hash_code' do
    it 'does not differ when the same object is built with the same params' do
      stage_1 = build(factory)
      stage_2 = build(factory)

      expect(stage_1.events_hash_code).to eq(stage_2.events_hash_code)
    end

    it 'differs when the stage events are different' do
      stage_1 = build(factory, start_event_identifier: :merge_request_created, end_event_identifier: :merge_request_merged)
      stage_2 = build(factory, start_event_identifier: :issue_created, end_event_identifier: :issue_first_mentioned_in_commit)

      expect(stage_1.events_hash_code).not_to eq(stage_2.events_hash_code)
    end
  end
end

RSpec.shared_examples 'value stream analytics label based stage' do
  context 'when creating label based event' do
    context 'when the label id is not passed' do
      it 'returns validation error when `start_event_label_id` is missing' do
        stage = described_class.new({
          name: 'My Stage',
          parent: parent,
          start_event_identifier: :issue_label_added,
          end_event_identifier: :issue_closed
        })

        expect(stage).to be_invalid
        expect(stage.errors[:start_event_label_id]).to include("can't be blank")
      end

      it 'returns validation error when `end_event_label_id` is missing' do
        stage = described_class.new({
          name: 'My Stage',
          parent: parent,
          start_event_identifier: :issue_closed,
          end_event_identifier: :issue_label_added
        })

        expect(stage).to be_invalid
        expect(stage.errors[:end_event_label_id]).to include("can't be blank")
      end
    end

    context 'when group label is defined on the root group' do
      it 'succeeds' do
        stage = described_class.new({
          name: 'My Stage',
          parent: parent,
          start_event_identifier: :issue_label_added,
          start_event_label_id: group_label.id,
          end_event_identifier: :issue_closed
        })

        expect(stage).to be_valid
      end
    end

    context 'when subgroup is given' do
      it 'succeeds' do
        stage = described_class.new({
          name: 'My Stage',
          parent: parent_in_subgroup,
          start_event_identifier: :issue_label_added,
          start_event_label_id: group_label.id,
          end_event_identifier: :issue_closed
        })

        expect(stage).to be_valid
      end
    end

    context 'when label is defined for a different group' do
      let(:error_message) { s_('CycleAnalyticsStage|is not available for the selected group') }

      it 'returns validation for `start_event_label_id`' do
        stage = described_class.new({
          name: 'My Stage',
          parent: parent_outside_of_group_label_scope,
          start_event_identifier: :issue_label_added,
          start_event_label_id: group_label.id,
          end_event_identifier: :issue_closed
        })

        expect(stage).to be_invalid
        expect(stage.errors[:start_event_label_id]).to include(error_message)
      end

      it 'returns validation for `end_event_label_id`' do
        stage = described_class.new({
          name: 'My Stage',
          parent: parent_outside_of_group_label_scope,
          start_event_identifier: :issue_closed,
          end_event_identifier: :issue_label_added,
          end_event_label_id: group_label.id
        })

        expect(stage).to be_invalid
        expect(stage.errors[:end_event_label_id]).to include(error_message)
      end
    end

    context 'when `ProjectLabel is given' do
      let_it_be(:label) { create(:label) }

      it 'raises error when `ProjectLabel` is given for `start_event_label`' do
        params = {
          name: 'My Stage',
          parent: parent,
          start_event_identifier: :issue_label_added,
          start_event_label: label,
          end_event_identifier: :issue_closed
        }

        expect { described_class.new(params) }.to raise_error(ActiveRecord::AssociationTypeMismatch)
      end

      it 'raises error when `ProjectLabel` is given for `end_event_label`' do
        params = {
          name: 'My Stage',
          parent: parent,
          start_event_identifier: :issue_closed,
          end_event_identifier: :issue_label_added,
          end_event_label: label
        }

        expect { described_class.new(params) }.to raise_error(ActiveRecord::AssociationTypeMismatch)
      end
    end
  end
end
