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
      end
    end
  end

  context 'when user is not allowed to retry pipeline' do
    it 'raises an error' do
      expect { service.execute }
        .to raise_error Gitlab::Access::AccessDeniedError
    end
  end

  def build(name)
    pipeline.statuses.find_by(name: name)
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
