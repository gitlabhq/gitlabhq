# frozen_string_literal: true

RSpec.shared_examples 'permission level for merge request mutation is correctly verified' do
  let(:other_user_author) { create(:user) }

  def mr_attributes(mr)
    mr.attributes.except(
      # Authors and assignees can edit title, description, target branch and draft status
      'title',
      'description',
      'target_branch',
      'draft',
      # Those fields are calculated or expected to be modified during the mutations
      'author_id',
      'latest_merge_request_diff_id',
      'last_edited_at',
      'last_edited_by_id',
      'lock_version',
      'updated_at',
      'updated_by_id',
      'merge_status',
      # There were spec failures due to nano-second comparisons
      # this property isn't changed by any mutation so we don't have to verify it
      'created_at'
    )
  end

  let(:expected) { mr_attributes(merge_request) }

  shared_examples_for 'when the user does not have access to the resource' do |raise_for_assigned_and_author|
    before do
      merge_request.assignees = []
      merge_request.reviewers = []
      merge_request.update!(author: other_user_author)
    end

    it 'raises an error' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end

    context 'even if assigned to the merge request' do
      before do
        merge_request.assignees.push(user)
      end

      it 'does not modify merge request' do
        if raise_for_assigned_and_author
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        else
          # In some cases we simply do nothing instead of raising
          # https://gitlab.com/gitlab-org/gitlab/-/issues/196241
          expect(mr_attributes(subject[:merge_request])).to eq expected
        end
      end
    end

    context 'even if reviewer of the merge request' do
      before do
        merge_request.reviewers.push(user)
      end

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'even if author of the merge request' do
      before do
        merge_request.update!(author: user)
      end

      it 'raises an error' do
        if raise_for_assigned_and_author
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        else
          # In some cases we simply do nothing instead of raising
          # https://gitlab.com/gitlab-org/gitlab/-/issues/196241
          expect(mr_attributes(subject[:merge_request])).to eq expected
        end
      end
    end
  end

  context 'when the user is not a project member' do
    it_behaves_like 'when the user does not have access to the resource', true
  end

  context 'when the user is a project member' do
    context 'with guest role' do
      before do
        merge_request.project.add_guest(user)
      end

      it_behaves_like 'when the user does not have access to the resource', true
    end

    context 'with reporter role' do
      before do
        merge_request.project.add_reporter(user)
      end

      it_behaves_like 'when the user does not have access to the resource', false
    end
  end
end
