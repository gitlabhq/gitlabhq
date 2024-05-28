# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating the dependency proxy image ttl policy', feature_category: :virtual_registry do
  include GraphqlHelpers

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

  shared_examples 'returning no response' do
    it 'returns no response', :aggregate_failures do
      subject

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response).to be_nil
    end
  end

  describe 'post graphql mutation' do
    subject { post_graphql_mutation(mutation, current_user: user) }

    let_it_be(:ttl_policy, reload: true) { create(:image_ttl_group_policy) }
    let_it_be(:group, reload: true) { ttl_policy.group }

    context 'without permission' do
      it_behaves_like 'returning no response'
    end

    context 'with permission' do
      context 'for owner' do
        before do
          group.add_owner(user)
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

      context 'for maintainer' do
        before do
          group.add_maintainer(user)
        end

        it_behaves_like 'returning no response'
      end
    end
  end
end
