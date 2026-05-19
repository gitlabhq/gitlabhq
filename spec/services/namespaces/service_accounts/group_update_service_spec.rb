# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::ServiceAccounts::GroupUpdateService, feature_category: :user_management do
  let_it_be(:organization) { create(:common_organization) }
  let_it_be(:group) { create(:group, organization: organization) }
  let_it_be(:other_group) { create(:group, organization: organization) }
  let_it_be(:owner) { create(:user) }
  let_it_be(:maintainer) { create(:user) }

  let(:service_account_user) { create(:user, :service_account, provisioned_by_group: group) }

  let(:params) do
    {
      name: FFaker::Name.name,
      username: "service_account_#{SecureRandom.hex(8)}",
      email: FFaker::Internet.email,
      group_id: group.id
    }
  end

  subject(:service) { described_class.new(current_user, service_account_user, params) }

  before_all do
    group.add_owner(owner)
    group.add_maintainer(maintainer)
  end

  describe '#execute' do
    context 'when current user is a group owner' do
      let(:current_user) { owner }

      it_behaves_like 'service account update success'

      context 'when saas', :saas do
        it_behaves_like 'service account update success'
      end

      context 'when params are empty' do
        let(:params) { {} }

        it 'returns a group not found error', :aggregate_failures do
          result = service.execute

          expect(result.status).to eq(:error)
          expect(result.message).to eq(s_('ServiceAccount|Group with the provided ID not found.'))
          expect(result.reason).to eq(:not_found)
        end
      end

      context 'when the provided group id does not match the service account group' do
        let(:params) { super().merge(group_id: other_group.id) }

        it 'returns an invalid group id error', :aggregate_failures do
          result = service.execute

          expect(result.status).to eq(:error)
          expect(result.message).to eq(
            s_("ServiceAccount|Group ID provided does not match the service account's group ID.")
          )
          expect(result.reason).to eq(:bad_request)
        end
      end

      context 'when email confirmation is off' do
        before do
          stub_application_setting_enum('email_confirmation_setting', 'off')
        end

        it 'updates the email directly without confirmation', :aggregate_failures do
          result = service.execute

          expect(result.status).to eq(:success)
          expect(result.payload[:user].email).to eq(params[:email])
          expect(result.payload[:user].unconfirmed_email).to be_nil
        end
      end

      context 'when email confirmation setting is set to hard' do
        before do
          stub_application_setting_enum('email_confirmation_setting', 'hard')
        end

        context 'when email is not provided' do
          let(:params) { super().except(:email) }

          it 'updates successfully without raising', :aggregate_failures do
            result = service.execute

            expect(result.status).to eq(:success)
          end
        end

        context 'when group owns the email domain' do
          it 'skips confirmation and updates the email directly', :aggregate_failures do
            resource = service.send(:resource)
            allow(resource).to receive(:owner_of_email?).with(params[:email]).and_return(true)

            result = service.execute

            expect(result.status).to eq(:success)
            expect(result.payload[:user].email).to eq(params[:email])
            expect(result.payload[:user].unconfirmed_email).to be_nil
          end
        end

        # domain_verification is EE-only - see ee/spec counterpart
      end
    end

    context 'when current user is a maintainer' do
      let(:current_user) { maintainer }

      it_behaves_like 'service account update not authorized'
    end
  end
end
