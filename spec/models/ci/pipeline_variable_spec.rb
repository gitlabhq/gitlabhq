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

    context 'without pipeline' do
      subject(:variable) { build(:ci_pipeline_variable, pipeline: nil, partition_id: nil) }

      it { is_expected.to validate_presence_of(:partition_id) }

      it 'does not change the partition_id value' do
        expect { variable.valid? }.not_to change(variable, :partition_id)
      end
    end
  end

  describe 'routing table switch' do
    context 'with ff disabled' do
      before do
        stub_feature_flags(ci_partitioning_use_ci_pipeline_variables_routing_table: false)
      end

      it 'uses the legacy table' do
        expect(described_class.table_name).to eq('ci_pipeline_variables')
      end
    end

    context 'with ff enabled' do
      before do
        stub_feature_flags(ci_partitioning_use_ci_pipeline_variables_routing_table: true)
      end

      it 'uses the routing table' do
        expect(described_class.table_name).to eq('p_ci_pipeline_variables')
      end
    end
  end
end
