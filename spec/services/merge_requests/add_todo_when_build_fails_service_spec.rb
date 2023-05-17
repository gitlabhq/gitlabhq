# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::MergeRequests::AddTodoWhenBuildFailsService, feature_category: :code_review_workflow do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:sha) { '1234567890abcdef1234567890abcdef12345678' }
  let(:ref) { merge_request.source_branch }

  let(:service) do
    described_class.new(project: project, current_user: user, params: { commit_message: 'Awesome message' })
  end

  let(:todo_service) { spy('todo service') }

  let(:merge_request) do
    create(:merge_request, :with_detached_merge_request_pipeline, :opened, merge_user: user)
  end

  let(:pipeline) do
    merge_request.all_pipelines.take
  end

  before do
    allow_any_instance_of(MergeRequest)
      .to receive(:head_pipeline_id)
      .and_return(pipeline.id)

    allow(service).to receive(:todo_service).and_return(todo_service)
  end

  describe '#execute' do
    context 'commit status with ref' do
      let(:commit_status) do
        create(:generic_commit_status, ref: ref, pipeline: pipeline)
      end

      it 'notifies the todo service' do
        expect(todo_service).to receive(:merge_request_build_failed).with(merge_request)
        service.execute(commit_status)
      end
    end

    context 'commit status with non-HEAD ref' do
      let(:commit_status) { create(:generic_commit_status, ref: ref) }

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

    context 'when commit status is a build allowed to fail' do
      let(:commit_status) do
        create(:ci_build, :allowed_to_fail, ref: ref, pipeline: pipeline)
      end

      it 'does not create todo' do
        expect(todo_service).not_to receive(:merge_request_build_failed)

        service.execute(commit_status)
      end
    end

    context 'when build belongs to a merge request pipeline' do
      let(:pipeline) do
        create(
          :ci_pipeline,
          source: :merge_request_event,
          ref: merge_request.merge_ref_path,
          merge_request: merge_request,
          merge_requests_as_head_pipeline: [merge_request]
        )
      end

      let(:commit_status) { create(:ci_build, ref: merge_request.merge_ref_path, pipeline: pipeline) }

      it 'notifies the todo service' do
        expect(todo_service).to receive(:merge_request_build_failed).with(merge_request)
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

    context 'when build belongs to a merge request pipeline' do
      let(:pipeline) do
        create(
          :ci_pipeline,
          source: :merge_request_event,
          ref: merge_request.merge_ref_path,
          merge_request: merge_request,
          merge_requests_as_head_pipeline: [merge_request]
        )
      end

      let(:commit_status) { create(:ci_build, ref: merge_request.merge_ref_path, pipeline: pipeline) }

      it 'notifies the todo service' do
        expect(todo_service).to receive(:merge_request_build_retried).with(merge_request)
        service.close(commit_status)
      end
    end
  end

  describe '#close_all' do
    context 'when using pipeline that belongs to merge request' do
      it 'resolves todos about failed builds for pipeline' do
        service.close_all(pipeline)

        expect(todo_service)
          .to have_received(:merge_request_build_retried)
          .with(merge_request)
      end
    end

    context 'when pipeline is not related to merge request' do
      let(:pipeline) { create(:ci_empty_pipeline) }

      it 'does not resolve any todos about failed builds' do
        service.close_all(pipeline)

        expect(todo_service)
          .not_to have_received(:merge_request_build_retried)
      end
    end
  end
end
