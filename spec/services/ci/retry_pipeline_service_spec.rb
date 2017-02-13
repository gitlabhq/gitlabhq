require 'spec_helper'

describe Ci::RetryPipelineService, '#execute', :services do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:service) { described_class.new(pipeline, user) }

  context 'when user has ability to modify pipeline' do
    let(:user) { create(:admin) }

    context 'when there are failed builds in the last stage' do
      before do
        create_build(name: 'rspec 1', status: :success, stage_num: 0)
        create_build(name: 'rspec 2', status: :failed, stage_num: 1)
        create_build(name: 'rspec 3', status: :canceled, stage_num: 1)
      end

      it 'enqueues all builds in the last stage' do
        service.execute

        expect(build('rspec 2')).to be_pending
        expect(build('rspec 3')).to be_pending
        expect(pipeline.reload).to be_running
      end
    end

    context 'when there are failed or canceled builds in the first stage' do
      before do
        create_build(name: 'rspec 1', status: :failed, stage_num: 0)
        create_build(name: 'rspec 2', status: :canceled, stage_num: 0)
        create_build(name: 'rspec 3', status: :skipped, stage_num: 1)
        create_build(name: 'deploy 1', status: :skipped, stage_num: 2)
      end

      it 'retries builds failed builds and marks subsequent for processing' do
        service.execute

        expect(build('rspec 1')).to be_pending
        expect(build('rspec 2')).to be_pending
        expect(build('rspec 3')).to be_created
        expect(build('deploy 1')).to be_created
        expect(pipeline.reload).to be_running
      end
    end

    context 'when there is failed build present which was run on failure' do
      before do
        create_build(name: 'rspec 1', status: :failed, stage_num: 0)
        create_build(name: 'rspec 2', status: :canceled, stage_num: 0)
        create_build(name: 'rspec 3', status: :skipped, stage_num: 1)
        create_build(name: 'report 1', status: :failed, stage_num: 2)
      end

      it 'retries builds failed builds and marks subsequent for processing' do
        service.execute

        expect(build('rspec 1')).to be_pending
        expect(build('rspec 2')).to be_pending
        expect(build('rspec 3')).to be_created
        expect(build('report 1')).to be_created
        expect(pipeline.reload).to be_running
      end

      it 'creates a new job for report job in this case' do
        service.execute

        expect(statuses.where(name: 'report 1').count).to eq 2
      end
    end
  end

  context 'when user is not allowed to retry pipeline' do
    it 'raises an error' do
      expect { service.execute }
        .to raise_error Gitlab::Access::AccessDeniedError
    end
  end

  def statuses
    pipeline.reload.statuses
  end

  def build(name)
    statuses.latest.find_by(name: name)
  end

  def create_build(name:, status:, stage_num:)
    create(:ci_build, name: name,
                      status: status,
                      stage: "stage_#{stage_num}",
                      stage_idx: stage_num,
                      pipeline: pipeline) do |build|
      pipeline.update_status
    end
  end
end
