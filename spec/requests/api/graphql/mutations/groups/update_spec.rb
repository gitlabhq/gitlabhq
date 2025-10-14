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

    context 'with step-up authentication provider' do
      let(:omniauth_provider_config_oidc) do
        GitlabSettings::Options.new(
          name: 'openid_connect',
          label: 'OpenID Connect',
          step_up_auth: {
            namespace: {
              id_token: {
                required: {
                  acr: 'gold'
                }
              }
            }
          }
        )
      end

      before do
        stub_omniauth_setting(enabled: true, providers: [omniauth_provider_config_oidc])
      end

      context 'when feature flag is enabled' do
        it 'updates step_up_auth_required_oauth_provider' do
          variables = {
            full_path: group.full_path,
            step_up_auth_required_oauth_provider: 'openid_connect'
          }

          mutation = graphql_mutation(:group_update, variables) do
            <<~QL
              group {
                namespaceSettings {
                  stepUpAuthRequiredOauthProvider
                }
              }
              errors
            QL
          end

          expect { post_graphql_mutation(mutation, current_user: user) }
            .to change { group.reload.step_up_auth_required_oauth_provider }
            .from(nil).to('openid_connect')

          expect(graphql_data_at(:group_update, :group, :namespaceSettings, :stepUpAuthRequiredOauthProvider))
            .to eq('openid_connect')
          expect(graphql_data_at(:group_update, :errors)).to be_empty
        end

        it 'clears setting with null value' do
          group.update!(step_up_auth_required_oauth_provider: 'openid_connect')

          variables = {
            full_path: group.full_path,
            step_up_auth_required_oauth_provider: nil
          }

          mutation = graphql_mutation(:group_update, variables) do
            <<~QL
              group {
                namespaceSettings {
                  stepUpAuthRequiredOauthProvider
                }
              }
            QL
          end

          expect { post_graphql_mutation(mutation, current_user: user) }
            .to change { group.reload.step_up_auth_required_oauth_provider }
            .from('openid_connect').to(nil)
        end

        it 'validates provider is in allowed list' do
          stub_omniauth_setting(enabled: true, providers: [])

          variables = {
            full_path: group.full_path,
            step_up_auth_required_oauth_provider: 'openid_connect'
          }

          mutation = graphql_mutation(:group_update, variables) do
            'errors'
          end

          post_graphql_mutation(mutation, current_user: user)

          expect(graphql_data_at(:group_update, :errors)).not_to be_empty
          expect(group.reload.step_up_auth_required_oauth_provider).to be_nil
        end

        it 'works for subgroups' do
          subgroup = create(:group, parent: group)
          subgroup.add_owner(user)

          variables = {
            full_path: subgroup.full_path,
            step_up_auth_required_oauth_provider: 'openid_connect'
          }

          mutation = graphql_mutation(:group_update, variables) do
            <<~QL
              group {
                namespaceSettings {
                  stepUpAuthRequiredOauthProvider
                }
              }
            QL
          end

          expect { post_graphql_mutation(mutation, current_user: user) }
            .to change { subgroup.reload.step_up_auth_required_oauth_provider }
            .from(nil).to('openid_connect')
        end
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(omniauth_step_up_auth_for_namespace: false)
        end

        it 'ignores the argument' do
          variables = {
            full_path: group.full_path,
            step_up_auth_required_oauth_provider: 'openid_connect'
          }

          mutation = graphql_mutation(:group_update, variables)

          expect { post_graphql_mutation(mutation, current_user: user) }
            .not_to change { group.reload.step_up_auth_required_oauth_provider }
        end
      end
    end
  end

  context 'when only updating step-up auth as non-admin' do
    let(:variables) do
      {
        full_path: group.full_path,
        step_up_auth_required_oauth_provider: 'openid_connect'
      }
    end

    before do
      group.add_maintainer(user)
      stub_omniauth_setting(enabled: true, providers: [
        GitlabSettings::Options.new(
          name: 'openid_connect',
          label: 'OpenID Connect',
          step_up_auth: {
            namespace: {
              id_token: {
                required: {
                  acr: 'gold'
                }
              }
            }
          }
        )
      ])
    end

    it 'returns an error' do
      post_graphql_mutation(mutation, current_user: user)

      expect(graphql_errors).not_to be_empty
      expect(group.reload.step_up_auth_required_oauth_provider).to be_nil
    end
  end
end
