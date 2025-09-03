# frozen_string_literal: true

# The context in which these shared examples are included
# need to have the following variables available:
#
# default_namespace_type - 'group, project or snippet'
# endpoint = '/groups, /projects or /snippets'
# params_with_public_visibility - necessary params for the post api() call
#
# How to use this:
#
# Ex:
# it_behaves_like 'restricted visibility level for API', 'group' do
#   let(:endpoint) { '/groups' }
#   let(:params_with_public_visibility) do
#     { name: 'test-group', path: 'test-group', visibility: 'public' }
#   end
# end
#
RSpec.shared_examples 'restricted visibility level for API' do |default_namespace_type|
  context "when the visibility level is restricted by an admin", :aggregate_failures do
    let(:admin) { create(:admin) }
    let(:token_with_admin_mode) { create(:personal_access_token, user: admin, scopes: %w[api admin_mode]) }
    let(:token_without_admin_mode) { create(:personal_access_token, user: admin, scopes: ['api']) }
    let(:restricted_visibility_level) { Gitlab::VisibilityLevel::PUBLIC }
    let(:restricted_visibility_string) { Gitlab::VisibilityLevel.string_level(Gitlab::VisibilityLevel::PUBLIC) }

    before do
      stub_application_setting(restricted_visibility_levels: [restricted_visibility_level])
    end

    context "with a PAT without an admin_mode scope" do
      it "fails to create a #{default_namespace_type} with restricted visibility" do
        post api(endpoint, personal_access_token: token_without_admin_mode), params: params_with_public_visibility

        expect(response).to have_gitlab_http_status(:bad_request).or have_gitlab_http_status(:forbidden)
        expect(json_response.to_s).to include("has been restricted by your GitLab administrator")
      end
    end

    context "with a PAT with an admin_mode scope" do
      it "creates a #{default_namespace_type} with restricted visibility" do
        post api(endpoint, personal_access_token: token_with_admin_mode), params: params_with_public_visibility

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['visibility']).to eq(restricted_visibility_string)
      end
    end
  end
end
