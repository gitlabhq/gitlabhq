# frozen_string_literal: true

require 'spec_helper'

describe PersonalAccessTokens::CreateService do
  describe '#execute' do
    context 'with valid params' do
      it 'creates personal access token record' do
        user = create(:user)
        params = { name: 'Test token', impersonation: true, scopes: [:api], expires_at: Date.today + 1.month }

        response = described_class.new(user, params).execute
        personal_access_token = response.payload[:personal_access_token]

        expect(response.success?).to be true
        expect(personal_access_token.name).to eq(params[:name])
        expect(personal_access_token.impersonation).to eq(params[:impersonation])
        expect(personal_access_token.scopes).to eq(params[:scopes])
        expect(personal_access_token.expires_at).to eq(params[:expires_at])
        expect(personal_access_token.user).to eq(user)
      end
    end
  end
end
