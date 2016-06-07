require 'spec_helper'

# Write specs in this file.
describe MergeRequests::AddTodoWhenBuildFailsService do
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request) }
  let(:project) { create(:project) }
  let(:sha) { '1234567890abcdef1234567890abcdef12345678' }
  let(:pipeline) { create(:ci_pipeline_with_one_job, ref: merge_request.source_branch, project: project, sha: sha) }
  let(:service) { MergeRequests::AddTodoWhenBuildFailsService.new(project, user, commit_message: 'Awesome message') }
  let(:todo_service) { TodoService.new }

  let(:merge_request) do
    create(:merge_request, merge_user: user, source_branch: 'master',
                           target_branch: 'feature', source_project: project, target_project: project,
                           state: 'opened')
  end

  before do
    allow_any_instance_of(MergeRequest).to receive(:pipeline).and_return(pipeline)
    allow(service).to receive(:todo_service).and_return(todo_service)
  end

  describe '#execute' do
    context 'commit status with ref' do
      let(:commit_status) { create(:generic_commit_status, ref: merge_request.source_branch, pipeline: pipeline) }

      it 'notifies the todo service' do
        expect(todo_service).to receive(:merge_request_build_failed).with(merge_request)
        service.execute(commit_status)
      end
    end

    context 'commit status with non-HEAD ref' do
      let(:commit_status) { create(:generic_commit_status, ref: merge_request.source_branch) }

      it 'does not notify the todo service' do
        expect(todo_service).not_to receive(:merge_request_build_failed)
        service.execute(commit_status)
      end
    end

    context 'commit status without ref' do
      let(:commit_status) { create(:generic_commit_status) }

      it 'does not notify the todo service' do
        expect(todo_service).not_to receive(:merge_request_build_failed)
        service.execute(commit_status)
      end
    end
  end

  describe '#close' do
    context 'commit status with ref' do
      let(:commit_status) { create(:generic_commit_status, ref: merge_request.source_branch, pipeline: pipeline) }

      it 'notifies the todo service' do
        expect(todo_service).to receive(:merge_request_build_retried).with(merge_request)
        service.close(commit_status)
      end
    end

    context 'commit status with non-HEAD ref' do
      let(:commit_status) { create(:generic_commit_status, ref: merge_request.source_branch) }

      it 'does not notify the todo service' do
        expect(todo_service).not_to receive(:merge_request_build_retried)
        service.close(commit_status)
      end
    end

    context 'commit status without ref' do
      let(:commit_status) { create(:generic_commit_status) }

      it 'does not notify the todo service' do
        expect(todo_service).not_to receive(:merge_request_build_retried)
        service.close(commit_status)
      end
    end
  end
end
