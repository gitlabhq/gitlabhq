# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Sources::Pipeline, feature_category: :continuous_integration do
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:pipeline) }

  it do
    is_expected.to belong_to(:build).class_name('Ci::Build')
      .with_foreign_key(:source_job_id).inverse_of(:sourced_pipelines)
  end

  it { is_expected.to belong_to(:source_project).class_name('::Project') }
  it { is_expected.to belong_to(:source_job) }
  it { is_expected.to belong_to(:source_bridge) }
  it { is_expected.to belong_to(:source_pipeline) }

  it { is_expected.to validate_presence_of(:project) }
  it { is_expected.to validate_presence_of(:pipeline) }

  it { is_expected.to validate_presence_of(:source_project) }
  it { is_expected.to validate_presence_of(:source_job) }
  it { is_expected.to validate_presence_of(:source_pipeline) }

  context 'loose foreign key on ci_sources_pipelines.source_project_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:project, namespace: create(:group)) }
      let!(:model) { create(:ci_sources_pipeline, source_project: parent) }
    end
  end

  context 'loose foreign key on ci_sources_pipelines.project_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:project, namespace: create(:group)) }
      let!(:model) { create(:ci_sources_pipeline, project: parent) }
    end
  end

  describe 'partitioning', :aggregate_failures do
    include Ci::PartitioningHelpers

    before do
      stub_current_partition_id(current_partition)
    end

    let_it_be(:current_partition) { ci_testing_partition_id }
    let_it_be(:older_partition) { ci_testing_partition_id - 1 }
    let_it_be(:pipeline) { create(:ci_pipeline, partition_id: older_partition) }

    context 'with child pipelines' do
      # The partition_id value is actually populated from the Pipeline::Chain::AssignPartition step
      let!(:child_pipeline) do
        create(:ci_pipeline, child_of: pipeline, partition_id: older_partition)
      end

      subject(:sources_pipeline) { child_pipeline.source_pipeline }

      it 'uses the same partition_id as the parent pipeline' do
        expect(sources_pipeline.partition_id).to eq(older_partition)
        expect(sources_pipeline.source_partition_id).to eq(older_partition)
        expect(child_pipeline.partition_id).to eq(older_partition)
      end
    end

    context 'with cross project pipelines' do
      # Uses current partition by default
      let!(:downstream) do
        create(:ci_pipeline, project: create(:project), child_of: pipeline)
      end

      subject(:sources_pipeline) { downstream.source_pipeline }

      it 'uses the current partition_id on new pipelines' do
        expect(sources_pipeline.partition_id).to eq(current_partition)
        expect(downstream.partition_id).to eq(current_partition)
        expect(sources_pipeline.source_pipeline_id).to eq(pipeline.id)
        expect(sources_pipeline.source_partition_id).to eq(older_partition)
      end
    end
  end
end
