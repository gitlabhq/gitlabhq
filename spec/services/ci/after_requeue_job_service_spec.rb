# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::AfterRequeueJobService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.owner }

  let(:pipeline) { create(:ci_pipeline, project: project) }

  let!(:test1) { create(:ci_build, :success, pipeline: pipeline, stage_idx: 1) }
  let!(:test2) { create(:ci_build, :skipped, pipeline: pipeline, stage_idx: 1) }
  let!(:build) { create(:ci_build, pipeline: pipeline, stage_idx: 0, name: 'build') }

  subject(:execute_service) { described_class.new(project, user).execute(build) }

  it 'marks subsequent skipped jobs as processable' do
    expect(test1.reload).to be_success
    expect(test2.reload).to be_skipped

    execute_service

    expect(test1.reload).to be_success
    expect(test2.reload).to be_created
  end

  context 'when there is a job need from the same stage' do
    let!(:test3) do
      create(:ci_build,
             :skipped,
             pipeline: pipeline,
             stage_idx: 0,
             scheduling_type: :dag)
    end

    before do
      create(:ci_build_need, build: test3, name: 'build')
    end

    it 'marks subsequent skipped jobs as processable' do
      expect { execute_service }.to change { test3.reload.status }.from('skipped').to('created')
    end

    context 'with ci_same_stage_job_needs FF disabled' do
      before do
        stub_feature_flags(ci_same_stage_job_needs: false)
      end

      it 'does nothing with the build' do
        expect { execute_service }.not_to change { test3.reload.status }
      end
    end
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
