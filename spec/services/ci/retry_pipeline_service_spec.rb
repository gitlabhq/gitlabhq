require 'spec_helper'

describe Ci::RetryPipelineService, '#execute', :services do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:service) { described_class.new(project, user) }

  context 'when user has ability to modify pipeline' do
    let(:user) { create(:admin) }

    context 'when there are failed builds in the last stage' do
      before do
        create_build('rspec 1', :success, 0)
        create_build('rspec 2', :failed, 1)
        create_build('rspec 3', :canceled, 1)
      end

      it 'enqueues all builds in the last stage' do
        service.execute(pipeline)

        expect(build('rspec 2')).to be_pending
        expect(build('rspec 3')).to be_pending
        expect(pipeline.reload).to be_running
      end
    end

    context 'when there are failed or canceled builds in the first stage' do
      before do
        create_build('rspec 1', :failed, 0)
        create_build('rspec 2', :canceled, 0)
        create_build('rspec 3', :canceled, 1)
        create_build('deploy 1', :canceled, 2)
      end

      it 'retries builds failed builds and marks subsequent for processing' do
        service.execute(pipeline)

        expect(build('rspec 1')).to be_pending
        expect(build('rspec 2')).to be_pending
        expect(build('rspec 3')).to be_created
        expect(build('deploy 1')).to be_created
        expect(pipeline.reload).to be_running
      end
    end

    context 'when there is failed build present which was run on failure' do
      before do
        create_build('rspec 1', :failed, 0)
        create_build('rspec 2', :canceled, 0)
        create_build('rspec 3', :canceled, 1)
        create_build('report 1', :failed, 2)
      end

      it 'retries builds failed builds and marks subsequent for processing' do
        service.execute(pipeline)

        expect(build('rspec 1')).to be_pending
        expect(build('rspec 2')).to be_pending
        expect(build('rspec 3')).to be_created
        expect(build('report 1')).to be_created
        expect(pipeline.reload).to be_running
      end

      it 'creates a new job for report job in this case' do
        service.execute(pipeline)

        # TODO, expect to be_retried
        expect(statuses.where(name: 'report 1').count).to eq 2
      end
    end

    context 'when there is canceled manual build in first stage' do
      before do
        create_build('rspec 1', :failed, 0)
        create_build('staging', :canceled, 0, :manual)
        create_build('rspec 2', :canceled, 1)
      end

      it 'retries builds failed builds and marks subsequent for processing' do
        service.execute(pipeline)

        expect(build('rspec 1')).to be_pending
        expect(build('staging')).to be_skipped
        expect(build('rspec 2')).to be_created
        expect(pipeline.reload).to be_running
      end
    end
  end

  context 'when user is not allowed to retry pipeline' do
    it 'raises an error' do
      expect { service.execute(pipeline) }
        .to raise_error Gitlab::Access::AccessDeniedError
    end
  end

  def statuses
    pipeline.reload.statuses
  end

  def build(name)
    statuses.latest.find_by(name: name)
  end

  def create_build(name, status, stage_num, on = 'on_success')
    create(:ci_build, name: name,
                      status: status,
                      stage: "stage_#{stage_num}",
                      stage_idx: stage_num,
                      when: on,
                      pipeline: pipeline) do |build|
      pipeline.update_status
    end
  end
end
