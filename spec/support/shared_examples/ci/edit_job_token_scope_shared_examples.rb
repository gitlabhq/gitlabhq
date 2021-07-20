# frozen_string_literal: true

RSpec.shared_examples 'editable job token scope' do
  shared_examples 'returns error' do |error|
    it 'returns an error response', :aggregate_failures do
      expect(result).to be_error
      expect(result.message).to eq(error)
    end
  end

  context 'when job token scope is disabled for the given project' do
    before do
      allow(project).to receive(:ci_job_token_scope_enabled?).and_return(false)
    end

    it_behaves_like 'returns error', 'Job token scope is disabled for this project'
  end

  context 'when user does not have permissions to edit the job token scope' do
    it_behaves_like 'returns error', 'Insufficient permissions to modify the job token scope'
  end

  context 'when user has permissions to edit the job token scope' do
    before do
      project.add_maintainer(current_user)
    end

    context 'when target project is not provided' do
      let(:target_project) { nil }

      it_behaves_like 'returns error', Ci::JobTokenScope::EditScopeValidations::TARGET_PROJECT_UNAUTHORIZED_OR_UNFOUND
    end

    context 'when target project is provided' do
      context 'when user does not have permissions to read the target project' do
        it_behaves_like 'returns error', Ci::JobTokenScope::EditScopeValidations::TARGET_PROJECT_UNAUTHORIZED_OR_UNFOUND
      end
    end
  end
end
