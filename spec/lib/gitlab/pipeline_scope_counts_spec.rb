# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PipelineScopeCounts do
  let(:current_user) { create(:user) }

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:failed_pipeline) { create(:ci_pipeline, :failed, project: project) }
  let_it_be(:success_pipeline) { create(:ci_pipeline, :success, project: project) }
  let_it_be(:ref_pipeline) { create(:ci_pipeline, project: project, ref: 'awesome-feature') }
  let_it_be(:sha_pipeline) { create(:ci_pipeline, :running, project: project, sha: 'deadbeef') }
  let_it_be(:on_demand_dast_scan) { create(:ci_pipeline, :success, project: project, source: 'ondemand_dast_scan') }

  before do
    project.add_developer(current_user)
  end

  it 'has policy class' do
    expect(described_class.declarative_policy_class).to be("Ci::ProjectPipelinesPolicy")
  end

  it 'has expected attributes' do
    expect(described_class.new(current_user, project, {})).to have_attributes(
      all: 6,
      finished: 3,
      pending: 2,
      running: 1
    )
  end

  describe 'with large amount of pipelines' do
    it 'sets the PIPELINES_COUNT_LIMIT constant to a value of 1_000' do
      expect(described_class::PIPELINES_COUNT_LIMIT).to eq(1_000)
    end

    context 'when there are more records than the limit' do
      before do
        stub_const('Gitlab::PipelineScopeCounts::PIPELINES_COUNT_LIMIT', 3)
      end

      it 'limits the found items' do
        expect(described_class.new(current_user, project, {}).all).to eq(3)
      end
    end
  end
end
