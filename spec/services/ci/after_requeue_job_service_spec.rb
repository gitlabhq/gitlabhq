# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::AfterRequeueJobService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.first_owner }

  let(:pipeline) { create(:ci_pipeline, project: project) }

  let!(:build1) { create(:ci_build, name: 'build1', pipeline: pipeline, stage_idx: 0) }
  let!(:test1) { create(:ci_build, :success, name: 'test1', pipeline: pipeline, stage_idx: 1) }
  let!(:test2) { create(:ci_build, :skipped, name: 'test2', pipeline: pipeline, stage_idx: 1) }
  let!(:test3) { create(:ci_build, :skipped, :dependent, name: 'test3', pipeline: pipeline, stage_idx: 1, needed: build1) }
  let!(:deploy) { create(:ci_build, :skipped, :dependent, name: 'deploy', pipeline: pipeline, stage_idx: 2, needed: test3) }

  subject(:execute_service) { described_class.new(project, user).execute(build1) }

  shared_examples 'processing subsequent skipped jobs' do
    it 'marks subsequent skipped jobs as processable' do
      expect(test1.reload).to be_success
      expect(test2.reload).to be_skipped
      expect(test3.reload).to be_skipped
      expect(deploy.reload).to be_skipped

      execute_service

      expect(test1.reload).to be_success
      expect(test2.reload).to be_created
      expect(test3.reload).to be_created
      expect(deploy.reload).to be_created
    end
  end

  it_behaves_like 'processing subsequent skipped jobs'

  context 'when there is a job need from the same stage' do
    let!(:build2) do
      create(:ci_build,
             :skipped,
             :dependent,
             name: 'build2',
             pipeline: pipeline,
             stage_idx: 0,
             scheduling_type: :dag,
             needed: build1)
    end

    shared_examples 'processing the same stage job' do
      it 'marks subsequent skipped jobs as processable' do
        expect { execute_service }.to change { build2.reload.status }.from('skipped').to('created')
      end
    end

    it_behaves_like 'processing subsequent skipped jobs'
    it_behaves_like 'processing the same stage job'
  end

  context 'when the pipeline is a downstream pipeline and the bridge is depended' do
    let!(:trigger_job) { create(:ci_bridge, :strategy_depend, name: 'trigger_job', status: 'success') }

    before do
      create(:ci_sources_pipeline, pipeline: pipeline, source_job: trigger_job)
    end

    it 'marks source bridge as pending' do
      expect { execute_service }.to change { trigger_job.reload.status }.from('success').to('pending')
    end
  end
end
