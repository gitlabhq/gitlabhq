# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::GroupDetail, feature_category: :groups_and_projects do
  describe '#as_json' do
    subject { described_class.new(group, options).as_json }

    let_it_be(:root_group) { create(:group) }
    let_it_be(:subgroup) { create(:group, :nested) }

    let(:options) { {} }

    describe '#prevent_sharing_groups_outside_hierarchy' do
      context 'for a root group' do
        let(:group) { root_group }

        it { is_expected.to include(:prevent_sharing_groups_outside_hierarchy) }
      end

      context 'for a subgroup' do
        let(:group) { subgroup }

        it { is_expected.not_to include(:prevent_sharing_groups_outside_hierarchy) }
      end
    end

    describe '#enabled_git_access_protocol' do
      using RSpec::Parameterized::TableSyntax

      where(:group, :can_admin_group, :includes_field) do
        ref(:root_group) | false | false
        ref(:root_group) | true | true
        ref(:subgroup) | false | false
        ref(:subgroup) | true | false
      end

      with_them do
        let(:options) { { user_can_admin_group: can_admin_group } }

        it 'verifies presence of the field' do
          if includes_field
            is_expected.to include(:enabled_git_access_protocol)
          else
            is_expected.not_to include(:enabled_git_access_protocol)
          end
        end
      end
    end

    describe '#step_up_auth_required_oauth_provider' do
      let(:group) { root_group }
      let(:options) { { user_can_admin_group: true } }

      it { is_expected.to include(:step_up_auth_required_oauth_provider) }

      context 'when user_can_admin_group is false' do
        let(:options) { { user_can_admin_group: false } }

        it { is_expected.not_to include(:step_up_auth_required_oauth_provider) }
      end

      context 'when namespace setting is blank' do
        before do
          allow(group).to receive(:namespace_settings).and_return(nil)
        end

        it { is_expected.not_to include(:step_up_auth_required_oauth_provider) }
      end

      context 'when step-up auth required oauth provider is set in namespace setting' do
        let(:openid_connect_config) do
          GitlabSettings::Options.new(
            name: 'openid_connect',
            step_up_auth: {
              namespace: {
                id_token: {
                  required: { acr: 'gold' }
                }
              }
            }
          )
        end

        before do
          stub_omniauth_setting(enabled: true, providers: [openid_connect_config])

          group.namespace_settings.update!(step_up_auth_required_oauth_provider: 'openid_connect')
        end

        it { is_expected.to include step_up_auth_required_oauth_provider: 'openid_connect' }
      end

      context 'when feature flag :omniauth_step_up_auth_for_namespace is disabled' do
        before do
          stub_feature_flags(omniauth_step_up_auth_for_namespace: false)
        end

        it { is_expected.not_to include(:step_up_auth_required_oauth_provider) }
      end
    end
  end
end
