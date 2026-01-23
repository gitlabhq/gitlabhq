# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::UsersController, :enable_admin_mode, feature_category: :user_management do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }

  before do
    sign_in(admin)
  end

  describe 'GET #index', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/570558' do
    it 'avoids N+1 query', :use_sql_query_cache do
      base_query_count = ActiveRecord::QueryRecorder.new(skip_cached: false) { get admin_users_path }

      create_list(:user, 3)

      expect { get admin_users_path }.not_to exceed_query_limit(base_query_count)
    end
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

    context "when admin changes email_otp_required_after" do
      let(:new_datetime) { 1.day.from_now.change(usec: 0) }

      it 'can be set to a datetime' do
        expect do
          patch admin_user_path(user), params: { user: { email_otp_required_after: new_datetime } }
        end.to change { user.reload.email_otp_required_after }.to(new_datetime)

        expect(response).to redirect_to(admin_user_path(user))
        expect(flash[:notice]).to eq('User was successfully updated.')
      end

      it 'can be set to nil' do
        user.update!(email_otp_required_after: 1.day.ago)

        expect do
          patch admin_user_path(user), params: { user: { email_otp_required_after: nil } }
        end.to change { user.reload.email_otp_required_after }.to(nil)

        expect(response).to redirect_to(admin_user_path(user))
        expect(flash[:notice]).to eq('User was successfully updated.')
      end

      context "when email OTP is required" do
        before do
          stub_application_setting(require_minimum_email_based_otp_for_users_with_passwords: true)
        end

        it 'cannot be set to nil' do
          user.update!(email_otp_required_after: 1.day.ago)

          expect do
            patch admin_user_path(user), params: { user: { email_otp_required_after: nil } }
          end.not_to change { user.reload.email_otp_required_after }

          expect(response).to redirect_to(admin_user_path(user))
        end
      end

      context "when email OTP is not permitted" do
        let(:admin) { create(:admin, :two_factor) }
        let(:user) { create(:user, :two_factor) }

        before do
          stub_application_setting(require_two_factor_authentication: true)
        end

        it 'cannot be set to a datetime' do
          expect do
            patch admin_user_path(user), params: { user: { email_otp_required_after: new_datetime } }
          end.not_to change { user.reload.email_otp_required_after }

          expect(response).to redirect_to(admin_user_path(user))
        end
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
