# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Conflicts::ResolveService, feature_category: :code_review_workflow do
  include ProjectForksHelper

  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository, developers: user) }

  let(:forked_project) do
    fork_project_with_submodules(project, user)
  end

  let(:merge_request) do
    create(
      :merge_request,
      source_branch: 'conflict-resolvable',
      source_project: project,
      target_branch: 'conflict-start',
      merge_status: :cannot_be_merged
    )
  end

  let(:merge_request_from_fork) do
    create(
      :merge_request,
      source_branch: 'conflict-resolvable-fork',
      source_project: forked_project,
      target_branch: 'conflict-start',
      target_project: project,
      merge_status: :cannot_be_merged
    )
  end

  before do
    allow(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter).to receive(:track_resolve_conflict_action)
  end

  describe '#execute' do
    let(:service) { described_class.new(merge_request) }

    let(:params) do
      {
        files: [
          {
            old_path: 'files/ruby/popen.rb',
            new_path: 'files/ruby/popen.rb',
            sections: {
              '2f6fcd96b88b36ce98c38da085c795a27d92a3dd_14_14' => 'head'
            }
          }, {
            old_path: 'files/ruby/regex.rb',
            new_path: 'files/ruby/regex.rb',
            sections: {
              '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_9_9' => 'head',
              '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_21_21' => 'origin',
              '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_49_49' => 'origin'
            }
          }
        ],
        commit_message: 'This is a commit message!'
      }
    end

    def blob_content(project, ref, path)
      project.repository.blob_at(ref, path).data
    end

    shared_examples 'a refusal before resolving' do
      it 'returns an error with the reason and does not resolve', :aggregate_failures do
        original_head_sha = project.repository.commit(merge_request.source_branch).sha

        result = service.execute(user, params)

        expect(result).to be_error
        expect(result.reason).to eq(reason)
        expect(result.message).to eq(message)
        expect(project.repository.commit(merge_request.source_branch).sha).to eq(original_head_sha)
        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .not_to have_received(:track_resolve_conflict_action)
      end
    end

    shared_examples 'a resolution error' do
      it 'returns a resolution error', :aggregate_failures do
        result = service.execute(user, invalid_params)

        expect(result).to be_error
        expect(result.reason).to eq(described_class::REASON_RESOLUTION_ERROR)
        expect(result.message).to be_present
      end
    end

    context 'with section params' do
      context 'when the source and target project are the same' do
        let!(:result) { service.execute(user, params) }

        it 'creates a commit with the message and returns a success response', :aggregate_failures do
          expect(merge_request.source_branch_head.message).to eq(params[:commit_message])
          expect(result).to be_success
          expect(result.payload).to eq(merge_request: merge_request)
          expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
            .to have_received(:track_resolve_conflict_action).with(user: user)
        end

        it 'creates a commit with the correct parents' do
          expect(merge_request.source_branch_head.parents.map(&:id))
            .to eq(%w[1450cd639e0bc6721eb02800169e464f212cde06
              824be604a34828eb682305f0d963056cfac87b2d])
        end
      end

      context 'when some files have trailing newlines' do
        let!(:source_head) do
          branch = 'conflict-resolvable'
          path = 'files/ruby/popen.rb'
          popen_content = blob_content(project, branch, path)

          project.repository.update_file(
            user,
            path,
            popen_content.chomp("\n"),
            message: 'Remove trailing newline from popen.rb',
            branch_name: branch
          )
        end

        before do
          service.execute(user, params)
        end

        it 'preserves trailing newlines from our side of the conflicts' do
          head_sha = merge_request.source_branch_head.sha
          popen_content = blob_content(project, head_sha, 'files/ruby/popen.rb')
          regex_content = blob_content(project, head_sha, 'files/ruby/regex.rb')

          expect(popen_content).not_to end_with("\n")
          expect(regex_content).to end_with("\n")
        end
      end

      context 'when the source project is a fork and does not contain the HEAD of the target branch' do
        let!(:target_head) do
          project.repository.create_file(
            user,
            'new-file-in-target',
            '',
            message: 'Add new file in target',
            branch_name: 'conflict-start')
        end

        subject do
          described_class.new(merge_request_from_fork).execute(user, params)
        end

        it 'creates a commit with the message' do
          subject

          expect(merge_request_from_fork.source_branch_head.message).to eq(params[:commit_message])
        end

        it 'creates a commit with the correct parents' do
          subject

          expect(merge_request_from_fork.source_branch_head.parents.map(&:id))
            .to eq(['404fa3fc7c2c9b5dacff102f353bdf55b1be2813', target_head])
        end
      end
    end

    context 'with content and sections params' do
      let(:popen_content) { "class Popen\nend" }

      let(:params) do
        {
          files: [
            {
              old_path: 'files/ruby/popen.rb',
              new_path: 'files/ruby/popen.rb',
              content: popen_content
            }, {
              old_path: 'files/ruby/regex.rb',
              new_path: 'files/ruby/regex.rb',
              sections: {
                '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_9_9' => 'head',
                '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_21_21' => 'origin',
                '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_49_49' => 'origin'
              }
            }
          ],
          commit_message: 'This is a commit message!'
        }
      end

      before do
        service.execute(user, params)
      end

      it 'creates a commit with the message' do
        expect(merge_request.source_branch_head.message).to eq(params[:commit_message])
      end

      it 'creates a commit with the correct parents' do
        expect(merge_request.source_branch_head.parents.map(&:id))
          .to eq(%w[1450cd639e0bc6721eb02800169e464f212cde06
            824be604a34828eb682305f0d963056cfac87b2d])
      end

      it 'sets the content to the content given' do
        blob = blob_content(
          merge_request.source_project,
          merge_request.source_branch_head.sha,
          'files/ruby/popen.rb'
        )

        expect(blob).to eq(popen_content)
      end
    end

    context 'when the user cannot push to the source branch' do
      let(:project) { create(:project, :public, :repository) }
      let(:reason) { described_class::REASON_NO_PUSH_ACCESS }
      let(:message) { 'Cannot push to source branch' }

      it_behaves_like 'a refusal before resolving'
    end

    context 'when the conflicts cannot be resolved in the UI' do
      let(:reason) { described_class::REASON_NOT_RESOLVABLE_IN_UI }
      let(:message) do
        'The merge conflicts for this merge request cannot be resolved through GitLab. ' \
          'Please try to resolve them locally.'
      end

      context 'when the merge request can be merged' do
        before do
          merge_request.update_column(:merge_status, :can_be_merged)
        end

        it_behaves_like 'a refusal before resolving'
      end

      context 'when the conflicts cannot be parsed' do
        before do
          allow(Gitlab::Git::Conflict::Parser).to receive(:parse)
            .and_raise(Gitlab::Git::Conflict::Parser::UnmergeableFile)
        end

        it_behaves_like 'a refusal before resolving'
      end
    end

    context 'when the conflicts are resolvable in the UI but the merge request can be merged' do
      before do
        allow_next_instance_of(MergeRequests::Conflicts::ListService) do |list_service|
          allow(list_service).to receive(:can_be_resolved_in_ui?).and_return(true)
        end

        merge_request.update_column(:merge_status, :can_be_merged)
      end

      it 'returns an already resolved error after tracking the attempt', :aggregate_failures do
        result = service.execute(user, params)

        expect(result).to be_error
        expect(result.reason).to eq(described_class::REASON_ALREADY_RESOLVED)
        expect(result.message).to eq('The merge conflicts for this merge request have already been resolved.')
        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .to have_received(:track_resolve_conflict_action).with(user: user)
      end
    end

    context 'when the push is rejected by a pre-receive hook' do
      before do
        allow_next_instance_of(Gitlab::Conflict::FileCollection) do |conflicts|
          allow(conflicts).to receive(:resolve)
            .and_raise(Gitlab::Git::PreReceiveError.new('GitLab: hook rejected the push'))
        end
      end

      it 'returns a pre-receive error with the hook message', :aggregate_failures do
        result = service.execute(user, params)

        expect(result).to be_error
        expect(result.reason).to eq(described_class::REASON_PRE_RECEIVE)
        expect(result.message).to eq('hook rejected the push')
      end
    end

    context 'when Gitaly fails while resolving' do
      before do
        allow_next_instance_of(Gitlab::Conflict::FileCollection) do |conflicts|
          allow(conflicts).to receive(:resolve).and_raise(Gitlab::Git::CommandError, 'error')
        end
      end

      it 'raises the error for the caller to handle' do
        expect { service.execute(user, params) }.to raise_error(Gitlab::Git::CommandError)
      end
    end

    context 'when a resolution section is missing' do
      let(:invalid_params) do
        {
          files: [
            {
              old_path: 'files/ruby/popen.rb',
              new_path: 'files/ruby/popen.rb',
              content: ''
            }, {
              old_path: 'files/ruby/regex.rb',
              new_path: 'files/ruby/regex.rb',
              sections: { '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_9_9' => 'head' }
            }
          ],
          commit_message: 'This is a commit message!'
        }
      end

      it_behaves_like 'a resolution error'
    end

    context 'when the content of a file is unchanged' do
      let(:resolver) do
        MergeRequests::Conflicts::ListService.new(merge_request).conflicts.resolver
      end

      let(:regex_conflict) do
        resolver.conflict_for_path(resolver.conflicts, 'files/ruby/regex.rb', 'files/ruby/regex.rb')
      end

      let(:invalid_params) do
        {
          files: [
            {
              old_path: 'files/ruby/popen.rb',
              new_path: 'files/ruby/popen.rb',
              content: ''
            }, {
              old_path: 'files/ruby/regex.rb',
              new_path: 'files/ruby/regex.rb',
              content: regex_conflict.content
            }
          ],
          commit_message: 'This is a commit message!'
        }
      end

      it_behaves_like 'a resolution error'
    end

    context 'when a file is missing' do
      let(:invalid_params) do
        {
          files: [
            {
              old_path: 'files/ruby/popen.rb',
              new_path: 'files/ruby/popen.rb',
              content: ''
            }
          ],
          commit_message: 'This is a commit message!'
        }
      end

      it_behaves_like 'a resolution error'
    end
  end
end
