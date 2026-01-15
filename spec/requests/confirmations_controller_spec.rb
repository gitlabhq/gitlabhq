# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ConfirmationsController, :with_current_organization, type: :request, feature_category: :system_access do
  describe '#show' do
    let_it_be_with_reload(:user) { create(:user, :unconfirmed) }
    let(:expected_context) do
      { 'meta.caller_id' => 'ConfirmationsController#show',
        'meta.user' => user.username }
    end

    let(:confirmation_token) do
      user.send_confirmation_instructions
      user.confirmation_token
    end

    let(:resource) { user }

    subject(:perform_request) do
      get user_confirmation_path, params: { confirmation_token: confirmation_token }
    end

    before do
      allow(Gitlab::AppLogger).to receive(:info)
    end

    shared_examples 'confirmation response' do |resource_name|
      it "confirms the #{resource_name}" do
        expect { perform_request }.to change { resource.reload.confirmed? }.from(false).to(true)

        # use a regexp to ignore query params and anchor
        expect(response).to redirect_to(Regexp.new(new_user_session_path))
        expect(flash[:notice]).to include('has been successfully confirmed')
      end

      context 'with blank confirmation_token' do
        let(:confirmation_token) { '' }

        it 'displays error message' do
          expect { perform_request }.not_to change { resource.reload.confirmed? }

          expect(response).to be_ok
          expect(response.body).to include(%r{Confirmation token.*be blank})
        end
      end

      context 'with invalid confirmation_token' do
        let(:confirmation_token) { 'fake-token-123' }

        it 'displays error message' do
          expect { perform_request }.not_to change { resource.reload.confirmed? }

          expect(response).to be_ok
          expect(response.body).to include(%r{Confirmation token.*invalid})
        end
      end
    end

    include_examples 'set_current_context'

    include_examples 'confirmation response', 'user'

    context 'when user cannot be found because incorrect organization specified' do
      let(:another_organization) { create(:organization) }

      before do
        stub_current_organization(another_organization)
      end

      it 'displays error message' do
        expect { perform_request }.not_to change { resource.reload.confirmed? }

        expect(response).to be_ok
        expect(response.body).to include('Organization is invalid')
      end
    end

    context 'for secondary email confirmation' do
      let_it_be_with_reload(:email) { create(:email, user: user) }
      let(:resource) { email }
      let(:user_id) { email.user_id }
      let(:confirmation_token)  { email.confirmation_token }

      subject(:perform_request) do
        get email_confirmation_path, params: { confirmation_token: confirmation_token, user_id: user_id }
      end

      before do
        email.send_confirmation_instructions
      end

      include_examples 'confirmation response', 'email'

      context 'when user cannot be found because of incorrect user_id' do
        let(:another_user) { create(:user) }
        let(:user_id) { another_user.id }

        it 'does not confirm secondary email' do
          expect { perform_request }.not_to change { email.reload.confirmed? }

          expect(response).to be_ok
          expect(response.body).to include('User is invalid')
        end
      end

      context 'when user_id is blank' do
        let(:user_id) { '' }

        # legacy behavior; to be removed in 18.11 or beyond once all
        # confirmations emails are guaranteed to have user_id parameter
        include_examples 'confirmation response', 'email'
      end

      context 'when user_id is nil' do
        let(:user_id) { nil }

        # legacy behavior; to be removed in 18.11 or beyond once all
        # confirmations emails are guaranteed to have user_id parameter
        include_examples 'confirmation response', 'email'
      end
    end
  end
end
