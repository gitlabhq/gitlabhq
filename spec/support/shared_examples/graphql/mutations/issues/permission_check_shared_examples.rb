# frozen_string_literal: true

RSpec.shared_examples 'permission level for issue mutation is correctly verified' do |raises_for_all_errors = false|
  before do
    issue.assignees = []
    issue.author = user
  end

  shared_examples_for 'when the user does not have access to the resource' do |raise_for_assigned|
    it 'raises an error' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end

    context 'even if assigned to the issue' do
      before do
        issue.assignees.push(user)
      end

      it 'does not modify issue' do
        if raises_for_all_errors || raise_for_assigned
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        else
          expect(subject[:issue]).to eq issue
        end
      end
    end

    context 'even if author of the issue' do
      before do
        issue.author = user
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
        issue.project.add_guest(user)
      end

      it_behaves_like 'when the user does not have access to the resource', false
    end
  end
end
