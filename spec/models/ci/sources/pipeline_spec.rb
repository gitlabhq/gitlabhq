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

  describe 'partitioning', :ci_partitionable do
    let!(:child_pipeline) { create(:ci_pipeline) }
    let!(:parent_pipeline) { create(:ci_pipeline, upstream_of: child_pipeline) }

    let(:current_partition) { ci_testing_partition_id_for_check_constraints }
    let(:older_partition) { ci_testing_partition_id_for_check_constraints - 1 }

    subject(:sources_pipeline) { child_pipeline.source_pipeline }

    it 'assigns partition_id and source_partition_id from pipeline and source_job', :aggregate_failures do
      expect(sources_pipeline.partition_id).to eq(current_partition)
      expect(sources_pipeline.source_partition_id).to eq(current_partition)
    end

    context 'when the upstream pipeline is from an older partition' do
      let!(:parent_pipeline) { create(:ci_pipeline, partition_id: older_partition, upstream_of: child_pipeline) }

      it 'assigns partition_id from the current partition' do
        expect(sources_pipeline.partition_id).to eq(current_partition)
      end

      it 'assigns source_partition_id to the older partition of the source pipeline' do
        expect(sources_pipeline.source_partition_id).to eq(older_partition)
      end
    end
  end
end
