# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::PersonalAccessTokens::CreateGranularService, feature_category: :system_access do
  describe '#execute' do
    subject(:execute) { service.execute }

    let_it_be(:current_user) { create(:user) }
    let_it_be(:organization) { create(:organization) }

    let(:granular_scopes) do
      [build(:granular_scope, boundary: ::Authz::Boundary.for(:user), organization: organization)]
    end

    let(:params) { { name: 'Test token', expires_at: Time.zone.today + 1.month, description: "Test Description" } }
    let(:service) do
      described_class.new(current_user: current_user, organization: organization, params: params,
        granular_scopes: granular_scopes)
    end

    let(:token) { execute.payload[:personal_access_token] }

    it 'creates a granular personal access token' do
      expect { execute }.to change { [PersonalAccessToken.count, Authz::GranularScope.count] }.to([1, 1])

      expect(token.user).to eq(current_user)
      expect(token.organization).to eq(organization)

      expect(token.name).to eq(params[:name])
      expect(token.description).to eq(params[:description])
      expect(token.expires_at).to eq(params[:expires_at])

      expect(token.scopes).to eq([::Gitlab::Auth::GRANULAR_SCOPE])
      expect(token).to be_granular
      expect(token.granular_scopes.map(&:id)).to match_array(granular_scopes.map(&:id))
    end

    describe 'internal event tracking' do
      let(:common_attrs) { { organization: organization } }
      let(:group) { create(:group, **common_attrs, guests: [current_user]) }
      let(:other_group) { create(:group, **common_attrs, guests: [current_user]) }
      let(:granular_scopes) do
        [
          build(:granular_scope, boundary: ::Authz::Boundary.for(:instance), **common_attrs,
            permissions: ['read_admin_member_role']),
          build(:granular_scope, boundary: ::Authz::Boundary.for(group), permissions: ['read_page']),
          build(:granular_scope, boundary: ::Authz::Boundary.for(other_group), permissions: ['delete_page'])
        ]
      end

      it 'tracks the creation event' do
        scopes = 'instance, groups_and_projects'
        permissions = 'instance: read_admin_member_role | groups_and_projects: delete_page, read_page'

        expect { execute }.to trigger_internal_events('create_pat')
          .with(user: current_user, additional_properties: { type: 'granular', scopes: scopes,
                                                             permissions: permissions })
          .and increment_usage_metrics('counts.count_total_personal_access_token_created_granular')
          .and not_increment_usage_metrics('counts.count_total_personal_access_token_created_legacy')
      end
    end

    context 'when no granular scopes are provided' do
      let(:service) do
        described_class.new(current_user: current_user, organization: organization, params: params, granular_scopes: [])
      end

      it 'returns an error response', :aggregate_failures do
        expect { execute }.not_to change { [PersonalAccessToken.count, Authz::GranularScope.count] }

        expect(execute).to be_error
        expect(execute.message).to eq('At least one granular scope must be provided')
      end
    end

    context 'when personal access token creation fails' do
      before do
        allow_next_instance_of(PersonalAccessTokens::CreateService) do |instance|
          allow(instance).to receive(:execute).and_return(
            ServiceResponse.error(message: 'Token creation failed')
          )
        end
      end

      it 'does not attempt to add granular scopes and returns the creation error', :aggregate_failures do
        expect(::Authz::GranularScopeService).not_to receive(:new)
        expect(execute).to be_error
        expect(execute.message).to eq('Token creation failed')
      end

      it 'does not trigger create event tracking' do
        expect { execute }.not_to trigger_internal_events('create_pat')
      end
    end

    context 'when addition of granular scopes fails' do
      before do
        allow_next_instance_of(Authz::GranularScopeService) do |instance|
          allow(instance).to receive(:add_granular_scopes).and_return(
            ServiceResponse.error(message: 'Granular scope addition failed')
          )
        end
      end

      it 'does not create a PersonalAccessToken record and returns the addition error', :aggregate_failures do
        expect { execute }.not_to change { [PersonalAccessToken.count, Authz::GranularScope.count] }

        expect(execute.message).to eq('Granular scope addition failed')
      end

      it 'does not trigger create event tracking' do
        expect { execute }.not_to trigger_internal_events('create_pat')
      end
    end
  end
end
