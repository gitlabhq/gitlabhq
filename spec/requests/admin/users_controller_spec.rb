# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::UsersController, :enable_admin_mode, feature_category: :user_management do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }

  before do
    sign_in(admin)
  end

  describe 'PATCH #update' do
    let(:user) { create(:user) }

    context "when admin changes user email" do
      let(:new_email) { 'new-email@example.com' }

      subject(:request) { patch admin_user_path(user), params: { user: { email: new_email } } }

      it 'allows change user email', :aggregate_failures do
        expect { request }
          .to change { user.reload.email }.from(user.email).to(new_email)

        expect(response).to redirect_to(admin_user_path(user))
        expect(flash[:notice]).to eq('User was successfully updated.')
      end

      it 'does not email the user with confirmation_instructions' do
        expect { request }
          .not_to have_enqueued_mail(DeviseMailer, :confirmation_instructions)
      end
    end
  end

  describe 'PUT #block' do
    context 'when request format is :json' do
      subject(:request) { put block_admin_user_path(user, format: :json) }

      context 'when user was blocked' do
        it 'returns 200 and json data with notice' do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to include('notice' => 'Successfully blocked')
        end
      end

      context 'when user was not blocked' do
        before do
          allow_next_instance_of(::Users::BlockService) do |service|
            allow(service).to receive(:execute).and_return({ status: :failed })
          end
        end

        it 'returns 200 and json data with error' do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to include('error' => 'Error occurred. User was not blocked')
        end
      end
    end
  end

  describe 'PUT #unlock' do
    before do
      user.lock_access!
    end

    subject(:request) { put unlock_admin_user_path(user) }

    it 'unlocks the user' do
      expect { request }.to change { user.reload.access_locked? }.from(true).to(false)
    end
  end

  describe 'PUT #trust' do
    subject(:request) { put trust_admin_user_path(user) }

    it 'trusts the user' do
      expect { request }.to change { user.reload.trusted? }.from(false).to(true)
    end

    context 'when setting trust fails' do
      before do
        allow_next_instance_of(Users::TrustService) do |instance|
          allow(instance).to receive(:execute).and_return({ status: :failed })
        end
      end

      it 'displays a flash alert' do
        request

        expect(response).to redirect_to(admin_user_path(user))
        expect(flash[:alert]).to eq(s_('Error occurred. User was not updated'))
      end
    end
  end

  describe 'PUT #untrust' do
    before do
      user.custom_attributes.create!(key: UserCustomAttribute::TRUSTED_BY, value: "placeholder")
    end

    subject(:request) { put untrust_admin_user_path(user) }

    it 'trusts the user' do
      expect { request }.to change { user.reload.trusted? }.from(true).to(false)
    end

    context 'when untrusting fails' do
      before do
        allow_next_instance_of(Users::UntrustService) do |instance|
          allow(instance).to receive(:execute).and_return({ status: :failed })
        end
      end

      it 'displays a flash alert' do
        request

        expect(response).to redirect_to(admin_user_path(user))
        expect(flash[:alert]).to eq(s_('Error occurred. User was not updated'))
      end
    end
  end
end
