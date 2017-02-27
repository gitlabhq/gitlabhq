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
        create_build('spinach 1', :canceled, 2)
      end

      it 'retries builds failed builds and marks subsequent for processing' do
        service.execute(pipeline)

        expect(build('rspec 1')).to be_pending
        expect(build('rspec 2')).to be_pending
        expect(build('rspec 3')).to be_created
        expect(build('spinach 1')).to be_created
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

      it 'retries builds only in the first stage' do
        service.execute(pipeline)

        expect(build('rspec 1')).to be_pending
        expect(build('rspec 2')).to be_pending
        expect(build('rspec 3')).to be_created
        expect(build('report 1')).to be_created
        expect(pipeline.reload).to be_running
      end

      it 'creates a new job for report job in this case' do
        service.execute(pipeline)

        expect(statuses.where(name: 'report 1').first).to be_retried
      end
    end

    context 'when the last stage was skipepd' do
      before do
        create_build('build 1', :success, 0)
        create_build('test 2', :failed, 1)
        create_build('report 3', :skipped, 2)
        create_build('report 4', :skipped, 2)
      end

      it 'retries builds only in the first stage' do
        service.execute(pipeline)

        expect(build('build 1')).to be_success
        expect(build('test 2')).to be_pending
        expect(build('report 3')).to be_created
        expect(build('report 4')).to be_created
        expect(pipeline.reload).to be_running
      end
    end

    context 'when pipeline contains manual actions' do
      context 'when there is a canceled manual action in first stage' do
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

      context 'when there is a skipped manual action in last stage' do
        before do
          create_build('rspec 1', :canceled, 0)
          create_build('rspec 2', :skipped, 0, :manual)
          create_build('staging', :skipped, 1, :manual)
        end

        it 'retries canceled job and reprocesses manual actions' do
          service.execute(pipeline)

          expect(build('rspec 1')).to be_pending
          expect(build('rspec 2')).to be_skipped
          expect(build('staging')).to be_created
          expect(pipeline.reload).to be_running
        end
      end

      context 'when there is a created manual action in the last stage' do
        before do
          create_build('rspec 1', :canceled, 0)
          create_build('staging', :created, 1, :manual)
        end

        it 'retries canceled job and does not update the manual action' do
          service.execute(pipeline)

          expect(build('rspec 1')).to be_pending
          expect(build('staging')).to be_created
          expect(pipeline.reload).to be_running
        end
      end

      context 'when there is a created manual action in the first stage' do
        before do
          create_build('rspec 1', :canceled, 0)
          create_build('staging', :created, 0, :manual)
        end

        it 'retries canceled job and skipps the manual action' do
          service.execute(pipeline)

          expect(build('rspec 1')).to be_pending
          expect(build('staging')).to be_skipped
          expect(pipeline.reload).to be_running
        end
      end
    end

    it 'closes all todos about failed jobs for pipeline' do
      expect(MergeRequests::AddTodoWhenBuildFailsService)
        .to receive_message_chain(:new, :close_all)

      service.execute(pipeline)
    end

    it 'reprocesses the pipeline' do
      expect(pipeline).to receive(:process!)

      service.execute(pipeline)
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
