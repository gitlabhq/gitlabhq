# frozen_string_literal: true

require 'spec_helper'

describe MergeRequestPollWidgetEntity do
  include ProjectForksHelper

  let(:project)  { create :project, :repository }
  let(:resource) { create(:merge_request, source_project: project, target_project: project) }
  let(:user)     { create(:user) }

  let(:request) { double('request', current_user: user, project: project) }

  subject do
    described_class.new(resource, request: request).as_json
  end

  it 'has default_merge_commit_message_with_description' do
    expect(subject[:default_merge_commit_message_with_description])
      .to eq(resource.default_merge_commit_message(include_description: true))
  end

  describe 'merge_pipeline' do
    it 'returns nil' do
      expect(subject[:merge_pipeline]).to be_nil
    end

    context 'when is merged' do
      let(:resource) { create(:merged_merge_request, source_project: project, merge_commit_sha: project.commit.id) }
      let(:pipeline) { create(:ci_empty_pipeline, project: project, ref: resource.target_branch, sha: resource.merge_commit_sha) }

      before do
        project.add_maintainer(user)
      end

      it 'returns merge_pipeline' do
        pipeline.reload
        pipeline_payload = PipelineDetailsEntity
                             .represent(pipeline, request: request)
                             .as_json

        expect(subject[:merge_pipeline]).to eq(pipeline_payload)
      end

      context 'when user cannot read pipelines on target project' do
        before do
          project.add_guest(user)
        end

        it 'returns nil' do
          expect(subject[:merge_pipeline]).to be_nil
        end
      end
    end
  end

  describe 'new_blob_path' do
    context 'when user can push to project' do
      it 'returns path' do
        project.add_developer(user)

        expect(subject[:new_blob_path])
          .to eq("/#{resource.project.full_path}/-/new/#{resource.source_branch}")
      end
    end

    context 'when user cannot push to project' do
      it 'returns nil' do
        expect(subject[:new_blob_path]).to be_nil
      end
    end
  end

  describe 'exposed_artifacts_path' do
    context 'when merge request has exposed artifacts' do
      before do
        expect(resource).to receive(:has_exposed_artifacts?).and_return(true)
      end

      it 'set the path to poll data' do
        expect(subject[:exposed_artifacts_path]).to be_present
      end
    end

    context 'when merge request has no exposed artifacts' do
      before do
        expect(resource).to receive(:has_exposed_artifacts?).and_return(false)
      end

      it 'set the path to poll data' do
        expect(subject[:exposed_artifacts_path]).to be_nil
      end
    end
  end

  describe 'auto merge' do
    context 'when auto merge is enabled' do
      let(:resource) { create(:merge_request, :merge_when_pipeline_succeeds) }

      it 'returns auto merge related information' do
        expect(subject[:auto_merge_strategy]).to eq('merge_when_pipeline_succeeds')
      end
    end

    context 'when auto merge is not enabled' do
      let(:resource) { create(:merge_request) }

      it 'returns auto merge related information' do
        expect(subject[:auto_merge_strategy]).to be_nil
      end
    end

    context 'when head pipeline is running' do
      before do
        create(:ci_pipeline, :running, project: project,
                                       ref: resource.source_branch,
                                       sha: resource.diff_head_sha)
        resource.update_head_pipeline
      end

      it 'returns available auto merge strategies' do
        expect(subject[:available_auto_merge_strategies]).to eq(%w[merge_when_pipeline_succeeds])
      end
    end

    context 'when head pipeline is finished' do
      before do
        create(:ci_pipeline, :success, project: project,
                                       ref: resource.source_branch,
                                       sha: resource.diff_head_sha)
        resource.update_head_pipeline
      end

      it 'returns available auto merge strategies' do
        expect(subject[:available_auto_merge_strategies]).to be_empty
      end
    end
  end

  describe 'pipeline' do
    let(:pipeline) { create(:ci_empty_pipeline, project: project, ref: resource.source_branch, sha: resource.source_branch_sha, head_pipeline_of: resource) }

    before do
      allow_any_instance_of(MergeRequestPresenter).to receive(:can?).and_call_original
      allow_any_instance_of(MergeRequestPresenter).to receive(:can?).with(user, :read_pipeline, anything).and_return(result)
    end

    context 'when user has access to pipelines' do
      let(:result) { true }

      context 'when is up to date' do
        let(:req) { double('request', current_user: user, project: project) }

        it 'returns pipeline' do
          pipeline_payload = PipelineDetailsEntity
            .represent(pipeline, request: req)
            .as_json

          expect(subject[:pipeline]).to eq(pipeline_payload)
        end
      end

      context 'when is not up to date' do
        it 'returns nil' do
          pipeline.update(sha: "not up to date")

          expect(subject[:pipeline]).to eq(nil)
        end
      end
    end

    context 'when user does not have access to pipelines' do
      let(:result) { false }

      it 'does not have pipeline' do
        expect(subject[:pipeline]).to eq(nil)
      end
    end
  end
end
