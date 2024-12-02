# frozen_string_literal: true

RSpec.shared_examples 'enforcing job token policies' do |policies|
  context 'when authenticating with a CI Job Token from another project' do
    let_it_be(:job) { create(:ci_build, :running, user: user) }
    let_it_be(:allowed_policies) { Array(policies) }
    let_it_be(:default_permissions) { false }

    before do
      create(:ci_job_token_project_scope_link,
        source_project: project,
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

    it { is_expected.to have_gitlab_http_status(:success) }

    context 'when the policies are not allowed' do
      let(:allowed_policies) { [] }

      it { is_expected.to have_gitlab_http_status(:forbidden) }

      it 'returns an error message containing the disallowed policy' do
        do_request

        expected_message = '403 Forbidden - Insufficient permissions to access this resource ' \
          "in project #{project.path}. "

        expected_message << if Array(policies).size == 1
                              "The following token permission is required: #{policies}."
                            else
                              "The following token permissions are required: #{Array(policies).to_sentence}."
                            end

        expect(json_response['message']).to eq(expected_message)
      end

      context 'when fine grained permissions are disabled' do
        let_it_be(:default_permissions) { true }

        it { is_expected.to have_gitlab_http_status(:success) }
      end

      context 'when the `enforce_job_token_policies` feature flag is disabled' do
        before do
          stub_feature_flags(enforce_job_token_policies: false)
        end

        it { is_expected.to have_gitlab_http_status(:success) }
      end
    end
  end
end
