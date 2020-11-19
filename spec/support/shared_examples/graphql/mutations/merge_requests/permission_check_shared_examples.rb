# frozen_string_literal: true

RSpec.shared_examples 'permission level for merge request mutation is correctly verified' do
  before do
    merge_request.assignees = []
    merge_request.reviewers = []
    merge_request.author = nil
  end

  shared_examples_for 'when the user does not have access to the resource' do |raise_for_assigned|
    it 'raises an error' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end

    context 'even if assigned to the merge request' do
      before do
        merge_request.assignees.push(user)
      end

      it 'does not modify merge request' do
        if raise_for_assigned
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        else
          # In some cases we simply do nothing instead of raising
          # https://gitlab.com/gitlab-org/gitlab/-/issues/196241
          expect(subject[:merge_request]).to eq merge_request
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
        merge_request.author = user
      end

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
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
