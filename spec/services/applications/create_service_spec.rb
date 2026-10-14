# frozen_string_literal: true

require "spec_helper"

RSpec.describe ::Applications::CreateService, feature_category: :system_access do
  include TestRequestHelpers

  let(:user) { create(:user) }

  subject(:service) { described_class.new(user, test_request, params) }

  context 'when scopes are present' do
    let(:params) { attributes_for(:application, scopes: ['read_user'], organization_id: user.organization.id) }

    it { expect { subject.execute }.to change { Authn::OauthApplication.count }.by(1) }

    it 'sets device_code_enabled to false for new applications' do
      expect(service.execute.device_code_enabled?).to be_falsy
    end

    it 'declares no granular scopes' do
      service.execute

      expect(service.declaration).to be_nil
    end

    it 'creates the application inside an open transaction' do
      ApplicationRecord.transaction do
        expect { service.execute }.to change { Authn::OauthApplication.count }.by(1)
      end
    end
  end

  context 'when scopes are missing' do
    let(:params) { attributes_for(:application, organization_id: user.organization.id) }

    it { expect { subject.execute }.not_to change { Authn::OauthApplication.count } }

    it 'includes blank scopes error message' do
      application = subject.execute

      expect(application.errors.full_messages).to include "Scopes can't be blank"
    end
  end

  context 'with granular scopes' do
    let_it_be(:private_group) { create(:group, :private) }

    let(:inputs) { [{ access: :user, permissions: %w[read_member_role] }] }
    let(:params) do
      attributes_for(:application, scopes: ['read_user'], organization_id: user.organization.id)
        .merge(owner: user, granular_scopes: inputs)
    end

    it 'creates the application with the declared set and the granular marker', :aggregate_failures do
      application = service.execute

      expect(application).to be_persisted
      expect(application.granular_scopes.map(&:access)).to eq(['user'])
      expect(application.scopes.to_a).to contain_exactly('read_user', 'granular')
      expect(service.declaration).to be_success
      expect(service.declaration.payload[:warnings]).to contain_exactly(
        'Tokens cannot use the MCP server without a user-level scope granting execute_mcp_tool.'
      )
    end

    context 'when the declaration is refused' do
      let(:inputs) do
        [{ access: :selected_memberships, permissions: %w[read_member_role], group_ids: [private_group.id] }]
      end

      it 'creates nothing and reports the reason', :aggregate_failures do
        application = nil

        expect { application = service.execute }
          .to not_change { Authn::OauthApplication.count }
          .and not_change { Authz::GranularScope.count }

        expect(application).not_to be_persisted
        expect(application.errors.full_messages)
          .to include('A selected group or project cannot be a boundary for this application.')
        expect(service.declaration).to be_error.and have_attributes(reason: :resource_not_allowed)
      end
    end

    context 'when called inside an open transaction' do
      it 'raises before writing anything' do
        expect do
          Authn::OauthApplication.transaction do
            expect { service.execute }.to raise_error(described_class::InsideTransactionError)
          end
        end.not_to change { Authn::OauthApplication.count }
      end
    end

    context 'when granular_scopes is empty' do
      let(:inputs) { [] }

      it 'creates the application without a declared set', :aggregate_failures do
        application = service.execute

        expect(application).to be_persisted
        expect(application.granular_scopes).to be_empty
        expect(application.scopes.to_a).to eq(['read_user'])
        expect(service.declaration).to be_success
      end
    end
  end
end
