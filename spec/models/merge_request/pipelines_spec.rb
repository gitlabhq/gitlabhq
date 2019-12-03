# frozen_string_literal: true

require 'spec_helper'

describe MergeRequest::Pipelines do
  describe '#all' do
    let(:merge_request) { create(:merge_request) }
    let(:project) { merge_request.source_project }

    subject { described_class.new(merge_request) }

    shared_examples 'returning pipelines with proper ordering' do
      let!(:all_pipelines) do
        merge_request.all_commit_shas.map do |sha|
          create(:ci_empty_pipeline,
            project: project, sha: sha, ref: merge_request.source_branch)
        end
      end

      it 'returns all pipelines' do
        expect(subject.all).not_to be_empty
        expect(subject.all).to eq(all_pipelines.reverse)
      end
    end

    context 'with single merge_request_diffs' do
      it_behaves_like 'returning pipelines with proper ordering'
    end

    context 'with multiple irrelevant merge_request_diffs' do
      before do
        merge_request.update(target_branch: 'v1.0.0')
      end

      it_behaves_like 'returning pipelines with proper ordering'
    end

    context 'with unsaved merge request' do
      let(:merge_request) { build(:merge_request) }

      let!(:pipeline) do
        create(:ci_empty_pipeline, project: project,
          sha: merge_request.diff_head_sha, ref: merge_request.source_branch)
      end

      it 'returns pipelines from diff_head_sha' do
        expect(subject.all).to contain_exactly(pipeline)
      end
    end

    context 'when pipelines exist for the branch and merge request' do
      let(:source_ref) { 'feature' }
      let(:target_ref) { 'master' }

      let!(:branch_pipeline) do
        create(:ci_pipeline, source: :push, project: project,
          ref: source_ref, sha: shas.second)
      end

      let!(:tag_pipeline) do
        create(:ci_pipeline, project: project, ref: source_ref, tag: true)
      end

      let!(:detached_merge_request_pipeline) do
        create(:ci_pipeline, source: :merge_request_event, project: project,
          ref: source_ref, sha: shas.second, merge_request: merge_request)
      end

      let(:merge_request) do
        create(:merge_request, source_project: project, source_branch: source_ref,
          target_project: project, target_branch: target_ref)
      end

      let(:project) { create(:project, :repository) }
      let(:shas) { project.repository.commits(source_ref, limit: 2).map(&:id) }

      before do
        create(:merge_request_diff_commit,
          merge_request_diff: merge_request.merge_request_diff,
          sha: shas.second, relative_order: 1)
      end

      it 'returns merge request pipeline first' do
        expect(subject.all).to eq([detached_merge_request_pipeline, branch_pipeline])
      end

      context 'when there are a branch pipeline and a merge request pipeline' do
        let!(:branch_pipeline_2) do
          create(:ci_pipeline, source: :push, project: project,
            ref: source_ref, sha: shas.first)
        end

        let!(:detached_merge_request_pipeline_2) do
          create(:ci_pipeline, source: :merge_request_event, project: project,
            ref: source_ref, sha: shas.first, merge_request: merge_request)
        end

        it 'returns merge request pipelines first' do
          expect(subject.all)
            .to eq([detached_merge_request_pipeline_2,
                    detached_merge_request_pipeline,
                    branch_pipeline_2,
                    branch_pipeline])
        end
      end

      context 'when there are multiple merge request pipelines from the same branch' do
        let!(:branch_pipeline_2) do
          create(:ci_pipeline, source: :push, project: project,
            ref: source_ref, sha: shas.first)
        end

        let!(:detached_merge_request_pipeline_2) do
          create(:ci_pipeline, source: :merge_request_event, project: project,
            ref: source_ref, sha: shas.first, merge_request: merge_request_2)
        end

        let(:merge_request_2) do
          create(:merge_request, source_project: project, source_branch: source_ref,
            target_project: project, target_branch: 'stable')
        end

        before do
          shas.each.with_index do |sha, index|
            create(:merge_request_diff_commit,
              merge_request_diff: merge_request_2.merge_request_diff,
              sha: sha, relative_order: index)
          end
        end

        it 'returns only related merge request pipelines' do
          expect(subject.all)
            .to eq([detached_merge_request_pipeline,
                    branch_pipeline_2,
                    branch_pipeline])

          expect(described_class.new(merge_request_2).all)
            .to eq([detached_merge_request_pipeline_2,
                    branch_pipeline_2,
                    branch_pipeline])
        end
      end

      context 'when detached merge request pipeline is run on head ref of the merge request' do
        let!(:detached_merge_request_pipeline) do
          create(:ci_pipeline, source: :merge_request_event, project: project,
            ref: merge_request.ref_path, sha: shas.second, merge_request: merge_request)
        end

        it 'sets the head ref of the merge request to the pipeline ref' do
          expect(detached_merge_request_pipeline.ref).to match(%r{refs/merge-requests/\d+/head})
        end

        it 'includes the detached merge request pipeline even though the ref is custom path' do
          expect(merge_request.all_pipelines).to include(detached_merge_request_pipeline)
        end
      end
    end
  end
end
