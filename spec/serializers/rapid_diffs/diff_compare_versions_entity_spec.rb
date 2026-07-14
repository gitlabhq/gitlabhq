# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapidDiffs::DiffCompareVersionsEntity, feature_category: :code_review_workflow do
  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Needs persisted objects
  let_it_be(:project) { create(:project, :repository) }

  let_it_be(:merge_request) do
    create(
      :merge_request,
      :skip_diff_creation,
      source_project: project,
      target_project: project
    )
  end

  let_it_be(:diff_1, freeze: false) { create(:merge_request_diff, merge_request: merge_request) }
  let_it_be(:diff_2, freeze: false) { create(:merge_request_diff, merge_request: merge_request) }
  let_it_be(:diff_3, freeze: false) { create(:merge_request_diff, merge_request: merge_request) }
  let_it_be(:head_diff, freeze: false) { create(:merge_request_diff, :merge_head, merge_request: merge_request) }
  # rubocop:enable RSpec/FactoryBot/AvoidCreate

  let(:options) do
    {
      diff_id: diff_1.id,
      start_sha: diff_3.head_commit_sha
    }
  end

  let(:diffable_merge_ref?) { true }
  let(:entity) { described_class.new(merge_request, options) }

  subject(:serialized) { entity.as_json }

  before_all do
    # These factories are getting created with `empty` as state so they can't be found
    # by the query used in the serializer.  We force them to be `collected` so they
    # can be found.
    [diff_1, diff_2, diff_3, head_diff].each { |diff| diff.update!(state: :collected) }
  end

  before do
    allow(merge_request).to receive(:diffable_merge_ref?).and_return(diffable_merge_ref?)
  end

  describe 'serialization' do
    it 'serializes source_versions using DiffSourceVersionEntity' do
      expect(RapidDiffs::DiffSourceVersionEntity).to receive(:represent)
        .with(
          [diff_3, diff_2, diff_1],
          merge_request: merge_request,
          merge_request_diffs: [diff_3, diff_2, diff_1],
          diff_id: options[:diff_id],
          start_sha: options[:start_sha],
          only_context_commits: false
        )
        .and_call_original

      expect(serialized).to have_key(:source_versions)
    end

    it 'serializes target_versions using DiffTargetVersionEntity' do
      expect(RapidDiffs::DiffTargetVersionEntity).to receive(:represent)
        .with(
          [head_diff, diff_2, diff_1],
          merge_request: merge_request,
          merge_request_diffs: [diff_3, diff_2, diff_1],
          diff_id: options[:diff_id],
          start_sha: options[:start_sha]
        )
        .and_call_original

      expect(serialized).to have_key(:target_versions)
    end

    context 'when HEAD diff is not diffable' do
      let(:diffable_merge_ref?) { false }

      it 'serializes target_versions using DiffTargetVersionEntity' do
        expect(RapidDiffs::DiffTargetVersionEntity).to receive(:represent)
          .with(
            [diff_3, diff_2, diff_1],
            merge_request: merge_request,
            merge_request_diffs: [diff_3, diff_2, diff_1],
            diff_id: options[:diff_id],
            start_sha: options[:start_sha]
          )
          .and_call_original

        serialized
      end
    end

    context 'when commit_id is present' do
      let(:commit) { project.repository.commits('master', limit: 1).map { |c| project.commit(c.id) }.first }
      let(:options) { { commit_id: commit.id } }

      before do
        allow_next_instance_of(::Gitlab::MergeRequests::CommitResolver, merge_request, commit.id) do |resolver|
          allow(resolver).to receive(:resolve).and_return(commit)
        end
      end

      it 'includes selected commit with full commit data and diff_refs' do
        expect(serialized[:commit]).to include(id: commit.id, short_id: Commit.truncate_sha(commit.id))
        expect(serialized[:commit]).to have_key(:commit_url)
        expect(serialized[:commit]).to have_key(:title_html)
        expect(serialized[:commit]).to have_key(:authored_date)
        expect(serialized[:commit]).to have_key(:diff_refs)
      end

      context 'with commit neighbors' do
        let(:commit_shas) do
          project.repository.commits('master', limit: 3).map(&:id)
        end

        before do
          allow(entity).to receive(:commit_ids).and_return(commit_shas)
        end

        context 'when commit is in the middle' do
          let(:commit) { project.commit(commit_shas[1]) }

          it 'includes both prev_commit_id and next_commit_id' do
            expect(serialized[:commit]).to include(
              next_commit_id: commit_shas[0],
              prev_commit_id: commit_shas[2]
            )
          end
        end

        context 'when commit is the newest (first in list)' do
          let(:commit) { project.commit(commit_shas[0]) }

          it 'has no next_commit_id' do
            expect(serialized[:commit]).to include(
              next_commit_id: nil,
              prev_commit_id: commit_shas[1]
            )
          end
        end

        context 'when commit is the oldest (last in list)' do
          let(:commit) { project.commit(commit_shas[2]) }

          it 'has no prev_commit_id' do
            expect(serialized[:commit]).to include(
              next_commit_id: commit_shas[1],
              prev_commit_id: nil
            )
          end
        end

        context 'when commit is not in the diff commits' do
          let(:commit) { project.commit(commit_shas[1]) }

          before do
            allow(entity).to receive(:commit_ids).and_return([])
          end

          it 'has nil for both neighbor IDs' do
            expect(serialized[:commit]).to include(
              next_commit_id: nil,
              prev_commit_id: nil
            )
          end
        end
      end
    end

    context 'when the commit_id does not resolve to a commit' do
      let(:commit) { project.repository.commits('master', limit: 1).map { |c| project.commit(c.id) }.first }
      let(:options) { { commit_id: commit.id } }

      before do
        allow_next_instance_of(::Gitlab::MergeRequests::CommitResolver, merge_request, commit.id) do |resolver|
          allow(resolver).to receive(:resolve).and_return(nil)
        end
      end

      it 'returns nil for commit' do
        expect(serialized[:commit]).to be_nil
      end
    end

    context 'when commit_id is not present' do
      it 'does not include commit' do
        expect(serialized).not_to have_key(:commit)
      end
    end

    describe 'context_commits' do
      let(:context_commits_diff) { instance_double(ContextCommitsDiff) }
      let(:diff_refs) do
        Gitlab::Diff::DiffRefs.new(
          base_sha: 'base_sha_abc',
          head_sha: 'head_sha_def',
          start_sha: 'base_sha_abc'
        )
      end

      before do
        allow(merge_request).to receive(:context_commits_diff).and_return(context_commits_diff)
      end

      context 'when context commits diff is empty' do
        before do
          allow(context_commits_diff).to receive(:empty?).and_return(true)
        end

        it 'is nil' do
          expect(serialized[:context_commits]).to be_nil
        end
      end

      context 'when context commits diff has commits' do
        before do
          allow(context_commits_diff).to receive_messages(
            empty?: false,
            commits_count: 3,
            diff_refs: diff_refs
          )
        end

        it 'exposes href, commits_count, selected and diff_refs' do
          expect(serialized[:context_commits]).to include(
            commits_count: 3,
            selected: false,
            diff_refs: {
              base_sha: 'base_sha_abc',
              head_sha: 'head_sha_def',
              start_sha: 'base_sha_abc'
            }
          )
          expect(serialized[:context_commits][:href]).to include('only_context_commits=true')
        end

        context 'when only_context_commits is true' do
          let(:options) do
            {
              diff_id: diff_1.id,
              start_sha: diff_3.head_commit_sha,
              only_context_commits: 'true'
            }
          end

          it 'marks context commits as selected' do
            expect(serialized[:context_commits][:selected]).to be(true)
          end

          it 'passes only_context_commits flag to source version entity' do
            expect(RapidDiffs::DiffSourceVersionEntity).to receive(:represent)
              .with(anything, hash_including(only_context_commits: true))
              .and_call_original

            serialized
          end
        end
      end
    end
  end
end
