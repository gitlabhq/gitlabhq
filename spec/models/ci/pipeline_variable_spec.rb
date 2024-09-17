# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineVariable, feature_category: :continuous_integration do
  subject { build(:ci_pipeline_variable) }

  it_behaves_like "CI variable"

  it { is_expected.to validate_presence_of(:key) }

  describe '#hook_attrs' do
    let(:variable) { create(:ci_pipeline_variable, key: 'foo', value: 'bar') }

    subject { variable.hook_attrs }

    it { is_expected.to be_a(Hash) }
    it { is_expected.to eq({ key: 'foo', value: 'bar' }) }
  end

  describe 'partitioning' do
    context 'with pipeline' do
      let(:pipeline) { build(:ci_pipeline, partition_id: 123) }
      let(:variable) { build(:ci_pipeline_variable, pipeline: pipeline, partition_id: nil) }

      it 'copies the partition_id from pipeline' do
        expect { variable.valid? }.to change(variable, :partition_id).from(nil).to(123)
      end
    end
  end

  describe '#ensure_project_id' do
    it 'sets the project_id before validation' do
      variable = build(:ci_pipeline_variable)
      variable.pipeline.project_id = variable.pipeline.project.id

      expect do
        variable.validate!
      end.to change { variable.project_id }.from(nil).to(variable.pipeline.project.id)
    end

    it 'does not override the project_id if set' do
      another_project = create(:project)
      variable = build(:ci_pipeline_variable, project_id: another_project.id)

      expect do
        variable.validate!
      end.not_to change { variable.project_id }.from(another_project.id)
    end
  end
end
