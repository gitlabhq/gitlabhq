require 'spec_helper'

describe MergeRequests::ResolveService do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  let(:fork_project) do
    create(:forked_project_with_submodules) do |fork_project|
      fork_project.build_forked_project_link(forked_to_project_id: fork_project.id, forked_from_project_id: project.id)
      fork_project.save
    end
  end

  let(:merge_request) do
    create(:merge_request,
           source_branch: 'conflict-resolvable', source_project: project,
           target_branch: 'conflict-start')
  end

  let(:merge_request_from_fork) do
    create(:merge_request,
           source_branch: 'conflict-resolvable-fork', source_project: fork_project,
           target_branch: 'conflict-start', target_project: project)
  end

  describe '#execute' do
    context 'with valid params' do
      let(:params) do
        {
          sections: {
            '2f6fcd96b88b36ce98c38da085c795a27d92a3dd_14_14' => 'head',
            '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_9_9' => 'head',
            '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_21_21' => 'origin',
            '6eb14e00385d2fb284765eb1cd8d420d33d63fc9_49_49' => 'origin'
          },
          commit_message: 'This is a commit message!'
        }
      end

      context 'when the source and target project are the same' do
        before do
          MergeRequests::ResolveService.new(project, user, params).execute(merge_request)
        end

        it 'creates a commit with the message' do
          expect(merge_request.source_branch_head.message).to eq(params[:commit_message])
        end

        it 'creates a commit with the correct parents' do
          expect(merge_request.source_branch_head.parents.map(&:id)).
            to eq(['1450cd639e0bc6721eb02800169e464f212cde06',
                   '75284c70dd26c87f2a3fb65fd5a1f0b0138d3a6b'])
        end
      end

      context 'when the source project is a fork and does not contain the HEAD of the target branch' do
        let!(:target_head) do
          project.repository.commit_file(user, 'new-file-in-target', '', 'Add new file in target', 'conflict-start', false)
        end

        before do
          MergeRequests::ResolveService.new(fork_project, user, params).execute(merge_request_from_fork)
        end

        it 'creates a commit with the message' do
          expect(merge_request_from_fork.source_branch_head.message).to eq(params[:commit_message])
        end

        it 'creates a commit with the correct parents' do
          expect(merge_request_from_fork.source_branch_head.parents.map(&:id)).
            to eq(['404fa3fc7c2c9b5dacff102f353bdf55b1be2813',
                   target_head])
        end
      end
    end

    context 'when a resolution is missing' do
      let(:invalid_params) { { sections: { '2f6fcd96b88b36ce98c38da085c795a27d92a3dd_14_14' => 'head' } } }
      let(:service) { MergeRequests::ResolveService.new(project, user, invalid_params) }

      it 'raises a MissingResolution error' do
        expect { service.execute(merge_request) }.
          to raise_error(Gitlab::Conflict::File::MissingResolution)
      end
    end
  end
end
