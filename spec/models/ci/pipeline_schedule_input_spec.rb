# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineScheduleInput, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project) }

  let_it_be(:persisted_input) do
    create(:ci_pipeline_schedule_input, pipeline_schedule: pipeline_schedule, project: project)
  end

  subject(:input) { persisted_input }

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:model) { create(:ci_pipeline_schedule_input, project: create(:project)) }
    let!(:parent) { model.project }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:pipeline_schedule) }
  end

  describe 'before_validation callback' do
    it "sets the input's project_id to the project_id of the pipeline schedule" do
      input = build(:ci_pipeline_schedule_input, pipeline_schedule: pipeline_schedule, project: nil)

      expect(input.project_id).to be_nil

      input.valid?

      expect(input.project_id).to eq(pipeline_schedule.project_id)
    end
  end

  describe 'validations' do
    describe 'name' do
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_length_of(:name).is_at_most(255) }
      it { is_expected.to validate_uniqueness_of(:name).scoped_to(:pipeline_schedule_id) }
    end

    describe 'value' do
      it 'allows falsey values' do
        input.value = false

        expect(input).to be_valid

        input.value = ''

        expect(input).to be_valid
      end

      context 'when the serialized length of the value is less than the maximum permitted size' do
        it 'is valid' do
          input.value = [1, 2]

          expect(input).to be_valid
        end
      end

      context 'when the serialized length of the value is greater than the maximum permitted size' do
        it 'is invalid' do
          stub_const("#{described_class}::MAX_VALUE_SIZE", 4)

          input.value = [1, 2]

          expect(input).not_to be_valid
          expect(input.errors.full_messages).to contain_exactly('Value exceeds max serialized size: 4 characters')
        end
      end
    end
  end
end
