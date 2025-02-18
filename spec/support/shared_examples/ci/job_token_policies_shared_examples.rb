# frozen_string_literal: true

RSpec.shared_examples 'enforcing job token policies' do |policies, expected_success_status: :success|
  context 'when authenticating with a CI job token from another project' do
    let(:source_project) { project }
    let(:target_job) { create(:ci_build, :running, user: user) }
    let(:allowed_policies) { Array(policies) }
    let(:default_permissions) { false }

    before do
      create(:ci_job_token_project_scope_link,
        source_project: source_project,
        target_project: target_job.project,
        direction: :inbound,
        job_token_policies: allowed_policies,
        default_permissions: default_permissions
      )
    end

    subject(:do_request) do
      request
      response
    end

    it { is_expected.to have_gitlab_http_status(expected_success_status) }

    context 'when the policies are not allowed' do
      let(:allowed_policies) { [] }

      it { is_expected.to have_gitlab_http_status(:forbidden) }

      it 'returns an error message containing the disallowed policy' do
        do_request

        expected_message = '403 Forbidden - Insufficient permissions to access this resource ' \
          "in project #{source_project.path}. "

        expected_message << if Array(policies).size == 1
                              "The following token permission is required: #{policies}."
                            else
                              "The following token permissions are required: #{Array(policies).to_sentence}."
                            end

        expect(json_response['message']).to eq(expected_message)
      end

      context 'when fine grained permissions are disabled' do
        let(:default_permissions) { true }

        it { is_expected.to have_gitlab_http_status(expected_success_status) }
      end

      context 'when the `add_policies_to_ci_job_token` feature flag is disabled' do
        before do
          stub_feature_flags(add_policies_to_ci_job_token: false)
        end

        it { is_expected.to have_gitlab_http_status(expected_success_status) }
      end
    end
  end
end
