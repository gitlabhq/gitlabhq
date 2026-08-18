# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationUsers::CreateService, feature_category: :organization do
  describe '#execute' do
    # Refind so the memoized `owner_user_ids` used by the policy is not shared between examples.
    let_it_be_with_refind(:organization) { create(:organization) }
    let_it_be(:user) { create(:user) }

    let(:user_type) { :owner }
    let(:params) { { username: user.username, user_type: user_type } }
    let(:organization_user) { response.payload[:organization_user] }

    subject(:response) { described_class.new(organization, current_user: current_user, params: params).execute }

    context 'when user does not have permission' do
      let_it_be(:current_user) { create(:user) }

      it 'returns an error' do
        expect(response).to be_error
        expect(response.message)
          .to match_array([_('You have insufficient permissions to create an organization user')])
      end

      it 'does not add the user to the organization' do
        expect { response }.not_to change { organization.organization_users.count }
      end
    end

    context 'when user has permission' do
      let_it_be(:organization_owner) { create(:organization_owner, organization: organization) }
      let_it_be(:current_user) { organization_owner.user }

      context 'when adding by username' do
        it 'adds the user with the requested access level' do
          expect(response).to be_success
          expect(organization_user.user).to eq(user)
          expect(organization_user.access_level).to eq(user_type.to_s)
        end

        it 'matches the username case insensitively' do
          params[:username] = user.username.upcase

          expect(response).to be_success
          expect(organization_user.user).to eq(user)
        end
      end

      context 'when adding by email' do
        let(:params) { { email: user.email, user_type: user_type } }

        it 'adds the user with the requested access level' do
          expect(response).to be_success
          expect(organization_user.user).to eq(user)
          expect(organization_user.access_level).to eq(user_type.to_s)
        end

        context 'when the email belongs to a confirmed secondary email' do
          let_it_be(:other_user) { create(:user) }
          let_it_be(:secondary_email) { create(:email, :confirmed, user: other_user) }

          let(:params) { { email: secondary_email.email, user_type: user_type } }

          it 'adds the owning user' do
            expect(response).to be_success
            expect(organization_user.user).to eq(other_user)
          end
        end

        context 'when the email is unconfirmed' do
          let_it_be(:unconfirmed_user) { create(:user, :unconfirmed) }

          let(:params) { { email: unconfirmed_user.email, user_type: user_type } }

          it 'returns a user not found error' do
            expect(response).to be_error
            expect(response.message).to match_array([_('The user could not be found')])
          end
        end
      end

      context 'when the identifier does not match a user' do
        let(:params) { { username: 'nonexistent-username', user_type: user_type } }

        it 'returns a user not found error and adds nobody' do
          expect { response }.not_to change { organization.organization_users.count }
          expect(response).to be_error
          expect(response.message).to match_array([_('The user could not be found')])
        end
      end

      context 'when the user is already part of the organization' do
        before do
          create(:organization_user, organization: organization, user: user)
        end

        it 'returns an already a member error and does not add the user again' do
          expect { response }.not_to change { organization.organization_users.count }
          expect(response).to be_error
          expect(response.message).to match_array([_('The user is already a member of the organization')])
        end
      end

      context "when the user's home organization is isolated" do
        let_it_be(:isolated_organization) { create(:organization, :isolated) }
        let_it_be(:user) { create(:user, organization: isolated_organization) }

        it 'returns an error and does not add the user' do
          expect { response }.not_to change { organization.organization_users.count }
          expect(response).to be_error
          expect(response.message)
            .to match_array([_('The user cannot be added because their home organization is isolated')])
        end
      end

      context 'when a record is invalid' do
        it 'returns an error and adds nobody' do
          allow_next_instance_of(Organizations::OrganizationUser) do |organization_user|
            allow(organization_user).to receive(:save!).and_raise(
              ActiveRecord::RecordInvalid, organization_user
            )
          end

          expect { response }.not_to change { organization.organization_users.count }
          expect(response).to be_error
        end
      end
    end
  end
end
