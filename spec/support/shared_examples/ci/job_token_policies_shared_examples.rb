# frozen_string_literal: true

RSpec.shared_examples 'enforcing job token policies' do |policies, expected_success_status: :success,
    allow_public_access_for_enabled_project_features: nil|

  shared_examples 'capturing job token policies' do
    it 'captures the policies' do
      expect(::Ci::JobToken::Authorization).to receive(:capture_job_token_policies)
        .with(Array(policies)).and_call_original

      do_request
    end
  end

  context 'when authenticating with a CI job token from another project' do
    let(:source_project) { project }
    let(:job_user) { user }
    let(:target_job) { create(:ci_build, :running, user: job_user) }
    let(:allowed_policies) { Array(policies) }
    let(:default_permissions) { false }
    let(:skip_allowlist_creation) { false }
    let!(:features_state) do
      source_project.project_feature.attributes
        .slice(*::ProjectFeature::FEATURES.map { |feature| "#{feature}_access_level" })
    end

    let!(:allowlist) do
      create(:ci_job_token_project_scope_link,
        source_project: source_project,
        target_project: target_job.project,
        direction: :inbound,
        job_token_policies: allowed_policies,
        default_permissions: default_permissions
      )
    end

    before do
      # Make all project features private
      enable_project_features(source_project, nil)
    end

    after do
      # Reinstate the initial project features
      source_project.project_feature.update!(features_state)
    end

    subject(:do_request) do
      request
      response
    end

    it { is_expected.to have_gitlab_http_status(expected_success_status) }

    context 'when the target project is not allowlisted and job token policies are disabled' do
      # We only want to enforce job token permissions for endpoints which are enforced by allowlists.
      # This test makes sure that endpoints for which we want to enable job token permissions
      # are denied access when an allowlist entry is missing.
      let(:allowlist) { nil }

      before do
        stub_feature_flags(add_policies_to_ci_job_token: false)
      end

      it 'denies access' do
        expect(do_request).to have_gitlab_http_status(:forbidden)
          .or have_gitlab_http_status(:not_found)
      end
    end

    it_behaves_like 'capturing job token policies'

    context 'when the policies are not allowed' do
      let(:allowed_policies) do
        (::Ci::JobToken::Policies::POLICIES - Array(policies)).take(1)
      end

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

        it_behaves_like 'capturing job token policies'
      end

      context 'when job token policies are disabled' do
        before do
          allow_next_found_instance_of(Project) do |project|
            allow(project).to receive(:job_token_policies_enabled?).and_return(false)
          end
        end

        it { is_expected.to have_gitlab_http_status(expected_success_status) }

        it_behaves_like 'capturing job token policies'
      end
    end

    context 'when the source project is public and the target job user is not a member of the source project' do
      let(:original_visibility_level) { source_project.visibility_level }
      let(:job_user) { create(:user) }

      # Make sure the source_project is public.
      before do
        if original_visibility_level != ::Gitlab::VisibilityLevel::PUBLIC
          source_project.update!(visibility_level: ::Gitlab::VisibilityLevel::PUBLIC)
        end
      end

      # If the source_project wasn't public, reset the visibility to it's original level
      after do
        if original_visibility_level != ::Gitlab::VisibilityLevel::PUBLIC
          source_project.update!(visibility_level: original_visibility_level)
        end
      end

      context 'when policies are not allowed, but the specified project features allow public access',
        if: allow_public_access_for_enabled_project_features.present? do
        let(:allowed_policies) { [] }

        context 'when all project features are private' do
          it { is_expected.to have_gitlab_http_status(:forbidden) }
        end

        context 'when the specified project features are public' do
          before do
            enable_project_features(source_project, allow_public_access_for_enabled_project_features)
          end

          it { is_expected.to have_gitlab_http_status(expected_success_status) }
        end
      end

      context 'when policies are allowed and all project features are public',
        unless: allow_public_access_for_enabled_project_features.present? do
        before do
          enable_project_features(source_project, ::ProjectFeature::FEATURES)
        end

        it 'denies access' do
          expect(do_request).to have_gitlab_http_status(:forbidden)
            .or have_gitlab_http_status(:unauthorized)
            .or have_gitlab_http_status(:bad_request)
        end
      end
    end
  end

  def enable_project_features(project, project_features)
    attrs = ::ProjectFeature::FEATURES.index_with(::ProjectFeature::PRIVATE)
    attrs.merge!(Array(project_features).index_with(::ProjectFeature::ENABLED)) if project_features.present?
    attrs.transform_keys! { |feature| "#{feature}_access_level" }
    project.project_feature.update!(attrs)
  end
end
