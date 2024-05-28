# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating the dependency proxy group settings', feature_category: :virtual_registry do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }

  let(:params) do
    {
      group_path: group.full_path,
      enabled: false
    }
  end

  let(:mutation) do
    graphql_mutation(:update_dependency_proxy_settings, params) do
      <<~QL
        dependencyProxySetting {
          enabled
        }
        errors
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:update_dependency_proxy_settings) }
  let(:group_settings) { mutation_response['dependencyProxySetting'] }

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

    let_it_be_with_reload(:group) { create(:group) }
    let_it_be_with_reload(:group_settings) { create(:dependency_proxy_group_setting, group: group) }

    context 'without permission' do
      it_behaves_like 'returning no response'
    end

    context 'with permission' do
      context 'for owner' do
        before_all do
          group.add_owner(user)
        end

        it 'returns the updated dependency proxy settings', :aggregate_failures do
          subject

          expect(response).to have_gitlab_http_status(:success)
          expect(mutation_response['errors']).to be_empty
          expect(group_settings[:enabled]).to eq(false)
        end
      end

      context 'for maintainer' do
        before_all do
          group.add_maintainer(user)
        end

        it_behaves_like 'returning no response'
      end
    end
  end
end
