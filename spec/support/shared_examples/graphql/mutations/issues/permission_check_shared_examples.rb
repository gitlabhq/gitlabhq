# frozen_string_literal: true

RSpec.shared_examples 'permission level for issue mutation is correctly verified' do |raises_for_all_errors = false|
  let_it_be(:other_user_author) { create(:user) }

  def issue_attributes(issue)
    issue.attributes.except(
      # Description and title can be updated by authors and assignees of the issues
      'description',
      'title',
      # Those fields are calculated or expected to be modified during the mutations
      'author_id',
      'updated_at',
      'updated_by_id',
      'last_edited_at',
      'last_edited_by_id',
      'lock_version',
      # There were spec failures due to nano-second comparisons
      # this property isn't changed by any mutation so we don't have to verify it
      'created_at'
    )
  end

  # TODO: .reload can be removed after the migration https://gitlab.com/gitlab-org/gitlab/-/issues/497857
  let(:expected) { issue_attributes(issue.reload) }

  shared_examples_for 'when the user does not have access to the resource' do |raise_for_assigned_and_author|
    before do
      issue.assignees = []
      issue.update!(author: other_user_author)
    end

    it 'raises an error' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end

    context 'even if assigned to the issue' do
      before do
        issue.assignees.push(current_user)
      end

      it 'does not modify issue' do
        if raises_for_all_errors || raise_for_assigned_and_author
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        else
          expect(issue_attributes(subject[:issue])).to eq expected
        end
      end
    end

    context 'even if author of the issue' do
      before do
        issue.update!(author: current_user)
      end

      it 'does not modify issue' do
        if raises_for_all_errors || raise_for_assigned_and_author
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        else
          expect(issue_attributes(subject[:issue])).to eq expected
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
        issue.project.add_guest(current_user)
      end

      it_behaves_like 'when the user does not have access to the resource', false
    end
  end
end
