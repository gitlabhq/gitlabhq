# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GroupUpdate', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:group) { create(:group) }

  let(:variables) do
    {
      full_path: group.full_path,
      shared_runners_setting: 'DISABLED_AND_OVERRIDABLE',

      # set to `false` since the default of this cascaded setting is `true`
      math_rendering_limits_enabled: false,
      lock_math_rendering_limits_enabled: true
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
        group.add_maintainer(user)
      end

      it_behaves_like 'unauthorized'
    end
  end

  context 'when authorized' do
    using RSpec::Parameterized::TableSyntax

    before do
      group.add_owner(user)
    end

    it 'updates math rendering settings' do
      post_graphql_mutation(mutation, current_user: user)

      expect(response).to have_gitlab_http_status(:success)
      expect(graphql_errors).to be_nil
      expect(group.reload.math_rendering_limits_enabled?).to be_falsey
      expect(group.reload.lock_math_rendering_limits_enabled?).to be_truthy
    end

    it 'updates shared runners settings' do
      post_graphql_mutation(mutation, current_user: user)

      expect(response).to have_gitlab_http_status(:success)
      expect(graphql_errors).to be_nil
      expect(group.reload.shared_runners_setting).to eq(variables[:shared_runners_setting].downcase)
    end

    where(:field, :value) do
      'name'   | 'foo bar'
      'path'   | 'foo-bar'
      'visibility' | 'private'
    end

    with_them do
      let(:variables) { { full_path: group.full_path, field => value } }

      it "updates #{params[:field]} field" do
        post_graphql_mutation(mutation, current_user: user)

        expect(graphql_data_at(:group_update, :group, field.to_sym)).to eq(value)
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
