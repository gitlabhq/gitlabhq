# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating the dependency proxy image ttl policy', feature_category: :dependency_proxy do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }

  let(:params) do
    {
      group_path: group.full_path,
      enabled: false,
      ttl: 2
    }
  end

  let(:mutation) do
    graphql_mutation(:update_dependency_proxy_image_ttl_group_policy, params) do
      <<~QL
        dependencyProxyImageTtlPolicy {
          enabled
          ttl
        }
        errors
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:update_dependency_proxy_image_ttl_group_policy) }
  let(:ttl_policy_response) { mutation_response['dependencyProxyImageTtlPolicy'] }

  before do
    stub_config(dependency_proxy: { enabled: true })
  end

  describe 'post graphql mutation' do
    subject { post_graphql_mutation(mutation, current_user: user) }

    let_it_be(:ttl_policy, reload: true) { create(:image_ttl_group_policy) }
    let_it_be(:group, reload: true) { ttl_policy.group }

    context 'without permission' do
      it 'returns no response' do
        subject

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response).to be_nil
      end
    end

    context 'with permission' do
      %i[owner maintainer].each do |role|
        context "for #{role}" do
          before do
            group.send("add_#{role}", user)
            stub_feature_flags(raise_group_admin_package_permission_to_owner: false)
          end

          it 'returns the updated dependency proxy image ttl policy', :aggregate_failures do
            subject

            expect(response).to have_gitlab_http_status(:success)
            expect(mutation_response['errors']).to be_empty
            expect(ttl_policy_response).to include(
              'enabled' => params[:enabled],
              'ttl' => params[:ttl]
            )
          end
        end
      end
    end
  end
end
