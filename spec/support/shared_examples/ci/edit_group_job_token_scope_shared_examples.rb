# frozen_string_literal: true

RSpec.shared_examples 'editable group job token scope' do
  shared_examples 'returns error' do |error|
    it 'returns an error response', :aggregate_failures do
      expect(result).to be_error
      expect(result.message).to eq(error)
    end
  end

  context 'when user does not have permissions to edit the job token scope' do
    it_behaves_like 'returns error', 'Insufficient permissions to modify the job token scope'
  end

  context 'when user has permissions to edit the job token scope' do
    before do
      project.add_maintainer(current_user)
    end

    context 'when target group is not provided' do
      let(:target_group) { nil }

      it_behaves_like 'returns error', Ci::JobTokenScope::EditScopeValidations::TARGET_GROUP_UNAUTHORIZED_OR_UNFOUND
    end

    context 'when target group is provided' do
      context 'when user does not have permissions to read the target group' do
        it_behaves_like 'returns error', Ci::JobTokenScope::EditScopeValidations::TARGET_GROUP_UNAUTHORIZED_OR_UNFOUND
      end
    end
  end
end
