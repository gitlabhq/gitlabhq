# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::AfterRequeueJobService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.owner }

  let(:pipeline) { create(:ci_pipeline, project: project) }

  let!(:build) { create(:ci_build, pipeline: pipeline, stage_idx: 0) }
  let!(:test1) { create(:ci_build, :success, pipeline: pipeline, stage_idx: 1) }
  let!(:test2) { create(:ci_build, :skipped, pipeline: pipeline, stage_idx: 1) }

  subject(:execute_service) { described_class.new(project, user).execute(build) }

  it 'marks subsequent skipped jobs as processable' do
    expect(test1.reload).to be_success
    expect(test2.reload).to be_skipped

    execute_service

    expect(test1.reload).to be_success
    expect(test2.reload).to be_created
  end

  context 'when the pipeline is a downstream pipeline and the bridge is depended' do
    let!(:trigger_job) { create(:ci_bridge, :strategy_depend, status: 'success') }

    before do
      create(:ci_sources_pipeline, pipeline: pipeline, source_job: trigger_job)
    end

    it 'marks source bridge as pending' do
      expect { execute_service }.to change { trigger_job.reload.status }.from('success').to('pending')
    end
  end
end
