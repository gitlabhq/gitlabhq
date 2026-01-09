# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::PersonalAccessTokens::CreateGranularService, feature_category: :system_access do
  describe '#execute' do
    subject(:execute) { service.execute }

    let_it_be(:current_user) { create(:user) }
    let_it_be(:organization) { create(:organization) }

    let(:granular_scope) { build(:granular_scope, boundary: ::Authz::Boundary.for(:user), organization: organization) }
    let(:params) { { name: 'Test token', expires_at: Time.zone.today + 1.month, description: "Test Description" } }
    let(:service) do
      described_class.new(current_user: current_user, organization: organization, params: params,
        granular_scopes: [granular_scope])
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
      expect(token.granular_scopes.map(&:id)).to match_array([granular_scope.id])
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
    end
  end
end
