# frozen_string_literal: true

RSpec.shared_examples 'enforcing job token policies' do |policy|
  context 'when authenticating with a CI Job Token from another project' do
    let_it_be(:user) { create(:user) }
    let_it_be(:job) { create(:ci_build, :running, user: user) }
    let_it_be(:accessed_project) { create(:project, developers: user) }
    let_it_be(:allowed_policies) { [policy] }
    let_it_be(:default_permissions) { false }

    before do
      create(:ci_job_token_project_scope_link,
        source_project: accessed_project,
        target_project: job.project,
        direction: :inbound,
        job_token_policies: allowed_policies,
        default_permissions: default_permissions
      )
    end

    subject(:do_request) do
      request
      response
    end

    it { is_expected.to have_gitlab_http_status(:ok) }

    context 'when the policy is not allowed' do
      let(:allowed_policies) { [] }

      it { is_expected.to have_gitlab_http_status(:forbidden) }

      it 'returns an error message containing the disallowed policy' do
        do_request
        expect(json_response['message']).to eq("403 Forbidden - Insufficient permissions to access this resource " \
          "in project #{accessed_project.path}. The following token permission is required: #{policy}.")
      end

      context 'when fine grained permissions are disabled' do
        let_it_be(:default_permissions) { true }

        it { is_expected.to have_gitlab_http_status(:ok) }
      end

      context 'when the `enforce_job_token_policies` feature flag is disabled' do
        before do
          stub_feature_flags(enforce_job_token_policies: false)
        end

        it { is_expected.to have_gitlab_http_status(:ok) }
      end
    end
  end
end
