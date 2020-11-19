# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TestHooks::ProjectService do
  let(:current_user) { create(:user) }

  describe '#execute' do
    let(:project) { create(:project, :repository) }
    let(:hook)    { create(:project_hook, project: project) }
    let(:trigger) { 'not_implemented_events' }
    let(:service) { described_class.new(hook, current_user, trigger) }
    let(:sample_data) { { data: 'sample' } }
    let(:success_result) { { status: :success, http_status: 200, message: 'ok' } }

    it 'allows to set a custom project' do
      project = double
      service.project = project

      expect(service.project).to eq(project)
    end

    context 'hook with not implemented test' do
      it 'returns error message' do
        expect(hook).not_to receive(:execute)
        expect(service.execute).to include({ status: :error, message: 'Testing not available for this hook' })
      end
    end

    context 'push_events' do
      let(:trigger) { 'push_events' }
      let(:trigger_key) { :push_hooks }

      it 'executes hook' do
        allow(Gitlab::DataBuilder::Push).to receive(:build_sample).and_return(sample_data)

        expect(hook).to receive(:execute).with(sample_data, trigger_key).and_return(success_result)
        expect(service.execute).to include(success_result)
      end
    end

    context 'tag_push_events' do
      let(:trigger) { 'tag_push_events' }
      let(:trigger_key) { :tag_push_hooks }

      it 'executes hook' do
        allow(Gitlab::DataBuilder::Push).to receive(:build_sample).and_return(sample_data)

        expect(hook).to receive(:execute).with(sample_data, trigger_key).and_return(success_result)
        expect(service.execute).to include(success_result)
      end
    end

    context 'note_events' do
      let(:trigger) { 'note_events' }
      let(:trigger_key) { :note_hooks }

      it 'returns error message if not enough data' do
        expect(hook).not_to receive(:execute)
        expect(service.execute).to include({ status: :error, message: 'Ensure the project has notes.' })
      end

      it 'executes hook' do
        allow(project).to receive(:notes).and_return([Note.new])
        allow(Gitlab::DataBuilder::Note).to receive(:build).and_return(sample_data)

        expect(hook).to receive(:execute).with(sample_data, trigger_key).and_return(success_result)
        expect(service.execute).to include(success_result)
      end
    end

    context 'issues_events' do
      let(:trigger) { 'issues_events' }
      let(:trigger_key) { :issue_hooks }
      let(:issue) { build(:issue) }

      it 'returns error message if not enough data' do
        expect(hook).not_to receive(:execute)
        expect(service.execute).to include({ status: :error, message: 'Ensure the project has issues.' })
      end

      it 'executes hook' do
        allow(project).to receive(:issues).and_return([issue])
        allow(issue).to receive(:to_hook_data).and_return(sample_data)

        expect(hook).to receive(:execute).with(sample_data, trigger_key).and_return(success_result)
        expect(service.execute).to include(success_result)
      end
    end

    context 'confidential_issues_events' do
      let(:trigger) { 'confidential_issues_events' }
      let(:trigger_key) { :confidential_issue_hooks }
      let(:issue) { build(:issue) }

      it 'returns error message if not enough data' do
        expect(hook).not_to receive(:execute)
        expect(service.execute).to include({ status: :error, message: 'Ensure the project has issues.' })
      end

      it 'executes hook' do
        allow(project).to receive(:issues).and_return([issue])
        allow(issue).to receive(:to_hook_data).and_return(sample_data)

        expect(hook).to receive(:execute).with(sample_data, trigger_key).and_return(success_result)
        expect(service.execute).to include(success_result)
      end
    end

    context 'merge_requests_events' do
      let(:trigger) { 'merge_requests_events' }
      let(:trigger_key) { :merge_request_hooks }

      it 'returns error message if not enough data' do
        expect(hook).not_to receive(:execute)
        expect(service.execute).to include({ status: :error, message: 'Ensure the project has merge requests.' })
      end

      it 'executes hook' do
        create(:merge_request, source_project: project)
        allow_any_instance_of(MergeRequest).to receive(:to_hook_data).and_return(sample_data)

        expect(hook).to receive(:execute).with(sample_data, trigger_key).and_return(success_result)
        expect(service.execute).to include(success_result)
      end
    end

    context 'job_events' do
      let(:trigger) { 'job_events' }
      let(:trigger_key) { :job_hooks }

      it 'returns error message if not enough data' do
        expect(hook).not_to receive(:execute)
        expect(service.execute).to include({ status: :error, message: 'Ensure the project has CI jobs.' })
      end

      it 'executes hook' do
        create(:ci_build, project: project)
        allow(Gitlab::DataBuilder::Build).to receive(:build).and_return(sample_data)

        expect(hook).to receive(:execute).with(sample_data, trigger_key).and_return(success_result)
        expect(service.execute).to include(success_result)
      end
    end

    context 'pipeline_events' do
      let(:trigger) { 'pipeline_events' }
      let(:trigger_key) { :pipeline_hooks }

      it 'returns error message if not enough data' do
        expect(hook).not_to receive(:execute)
        expect(service.execute).to include({ status: :error, message: 'Ensure the project has CI pipelines.' })
      end

      it 'executes hook' do
        create(:ci_empty_pipeline, project: project)
        allow(Gitlab::DataBuilder::Pipeline).to receive(:build).and_return(sample_data)

        expect(hook).to receive(:execute).with(sample_data, trigger_key).and_return(success_result)
        expect(service.execute).to include(success_result)
      end
    end

    context 'wiki_page_events' do
      let(:project) { create(:project, :wiki_repo) }
      let(:trigger) { 'wiki_page_events' }
      let(:trigger_key) { :wiki_page_hooks }

      it 'returns error message if wiki disabled' do
        allow(project).to receive(:wiki_enabled?).and_return(false)

        expect(hook).not_to receive(:execute)
        expect(service.execute).to include({ status: :error, message: 'Ensure the wiki is enabled and has pages.' })
      end

      it 'returns error message if not enough data' do
        expect(hook).not_to receive(:execute)
        expect(service.execute).to include({ status: :error, message: 'Ensure the wiki is enabled and has pages.' })
      end

      it 'executes hook' do
        create(:wiki_page, wiki: project.wiki)
        allow(Gitlab::DataBuilder::WikiPage).to receive(:build).and_return(sample_data)

        expect(hook).to receive(:execute).with(sample_data, trigger_key).and_return(success_result)
        expect(service.execute).to include(success_result)
      end
    end

    context 'releases_events' do
      let(:trigger) { 'releases_events' }
      let(:trigger_key) { :release_hooks }

      it 'returns error message if not enough data' do
        expect(hook).not_to receive(:execute)
        expect(service.execute).to include({ status: :error, message: 'Ensure the project has releases.' })
      end

      it 'executes hook' do
        allow(project).to receive(:releases).and_return([Release.new])
        allow_any_instance_of(Release).to receive(:to_hook_data).and_return(sample_data)

        expect(hook).to receive(:execute).with(sample_data, trigger_key).and_return(success_result)
        expect(service.execute).to include(success_result)
      end
    end
  end
end
