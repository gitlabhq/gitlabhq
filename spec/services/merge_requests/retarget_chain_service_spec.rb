# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::RetargetChainService do
  include ProjectForksHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request, reload: true) { create(:merge_request, assignees: [user]) }
  let_it_be(:project) { merge_request.project }

  subject { described_class.new(project: project, current_user: user).execute(merge_request) }

  before do
    project.add_maintainer(user)
  end

  describe '#execute' do
    context 'when there is another MR' do
      let!(:another_merge_request) do
        create(:merge_request,
          source_project: source_project,
          source_branch: 'my-awesome-feature',
          target_project: merge_request.source_project,
          target_branch: merge_request.source_branch
        )
      end

      shared_examples 'does not retarget merge request' do
        it 'another merge request is unchanged' do
          expect { subject }.not_to change { another_merge_request.reload.target_branch }
            .from(merge_request.source_branch)
        end
      end

      shared_examples 'retargets merge request' do
        it 'another merge request is retargeted' do
          expect(SystemNoteService)
            .to receive(:change_branch).once
            .with(another_merge_request, another_merge_request.project, user,
              'target', 'delete',
              merge_request.source_branch, merge_request.target_branch)

          expect { subject }.to change { another_merge_request.reload.target_branch }
            .from(merge_request.source_branch)
            .to(merge_request.target_branch)
        end

        context 'when FF retarget_merge_requests is disabled' do
          before do
            stub_feature_flags(retarget_merge_requests: false)
          end

          include_examples 'does not retarget merge request'
        end
      end

      context 'in the same project' do
        let(:source_project) { project }

        context 'and current is merged' do
          before do
            merge_request.mark_as_merged
          end

          it_behaves_like 'retargets merge request'
        end

        context 'and current is closed' do
          before do
            merge_request.close
          end

          it_behaves_like 'does not retarget merge request'
        end

        context 'and another is closed' do
          before do
            another_merge_request.close
          end

          it_behaves_like 'does not retarget merge request'
        end

        context 'and another is merged' do
          before do
            another_merge_request.mark_as_merged
          end

          it_behaves_like 'does not retarget merge request'
        end
      end

      context 'in forked project' do
        let!(:source_project) { fork_project(project) }

        context 'when user has access to source project' do
          before do
            source_project.add_developer(user)
            merge_request.mark_as_merged
          end

          it_behaves_like 'retargets merge request'
        end

        context 'when user does not have access to source project' do
          it_behaves_like 'does not retarget merge request'
        end
      end

      context 'and current and another MR is from a fork' do
        let(:project) { create(:project) }
        let(:source_project) { fork_project(project) }

        let(:merge_request) do
          create(:merge_request,
            source_project: source_project,
            target_project: project
          )
        end

        before do
          source_project.add_developer(user)
        end

        it_behaves_like 'does not retarget merge request'
      end
    end

    context 'when many merge requests are to be retargeted' do
      let!(:many_merge_requests) do
        create_list(:merge_request, 10, :unique_branches,
          source_project: merge_request.source_project,
          target_project: merge_request.source_project,
          target_branch: merge_request.source_branch
        )
      end

      before do
        merge_request.mark_as_merged
      end

      it 'retargets only 4 of them' do
        subject

        expect(many_merge_requests.each(&:reload).pluck(:target_branch).tally)
          .to eq(
            merge_request.source_branch => 6,
            merge_request.target_branch => 4
          )
      end
    end
  end
end
