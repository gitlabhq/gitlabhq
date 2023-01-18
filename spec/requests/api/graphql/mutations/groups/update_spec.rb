# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GroupUpdate', feature_category: :subgroups do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:group) { create(:group) }

  let(:variables) do
    {
      full_path: group.full_path,
      shared_runners_setting: 'DISABLED_AND_OVERRIDABLE'
    }
  end

  let(:mutation) { graphql_mutation(:group_update, variables) }

  context 'when unauthorized' do
    shared_examples 'unauthorized' do
      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: user)

        expect(graphql_errors).not_to be_empty
      end
    end

    context 'when not a group member' do
      it_behaves_like 'unauthorized'
    end

    context 'when a non-admin group member' do
      before do
        group.add_developer(user)
      end

      it_behaves_like 'unauthorized'
    end
  end

  context 'when authorized' do
    before do
      group.add_owner(user)
    end

    it 'updates shared runners settings' do
      post_graphql_mutation(mutation, current_user: user)

      expect(response).to have_gitlab_http_status(:success)
      expect(graphql_errors).to be_nil
      expect(group.reload.shared_runners_setting).to eq(variables[:shared_runners_setting].downcase)
    end

    context 'when using DISABLED_WITH_OVERRIDE (deprecated)' do
      let(:variables) do
        {
          full_path: group.full_path,
          shared_runners_setting: 'DISABLED_WITH_OVERRIDE'
        }
      end

      it 'updates shared runners settings with disabled_and_overridable' do
        post_graphql_mutation(mutation, current_user: user)

        expect(response).to have_gitlab_http_status(:success)
        expect(graphql_errors).to be_nil
        expect(group.reload.shared_runners_setting).to eq('disabled_and_overridable')
      end
    end

    context 'when bad arguments are provided' do
      let(:variables) { { full_path: '', shared_runners_setting: 'INVALID' } }

      it 'returns the errors' do
        post_graphql_mutation(mutation, current_user: user)

        expect(graphql_errors).not_to be_empty
        expect(group.reload.shared_runners_setting).to eq('enabled')
      end
    end
  end
end
