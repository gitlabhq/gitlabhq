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
    include Ci::PartitioningHelpers

    let(:new_pipeline) { create(:ci_pipeline) }
    let(:source_pipeline) { create(:ci_sources_pipeline, pipeline: new_pipeline) }

    before do
      stub_current_partition_id
    end

    it 'assigns partition_id and source_partition_id from pipeline and source_job', :aggregate_failures do
      expect(source_pipeline.partition_id).to eq(ci_testing_partition_id)
      expect(source_pipeline.source_partition_id).to eq(ci_testing_partition_id)
    end
  end
end
