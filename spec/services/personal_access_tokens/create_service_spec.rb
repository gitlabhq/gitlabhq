# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokens::CreateService do
  shared_examples_for 'a successfully created token' do
    it 'creates personal access token record' do
      expect(subject.success?).to be true
      expect(token.name).to eq(params[:name])
      expect(token.impersonation).to eq(params[:impersonation])
      expect(token.scopes).to eq(params[:scopes])
      expect(token.expires_at).to eq(params[:expires_at])
      expect(token.user).to eq(user)
    end

    it 'logs the event' do
      expect(Gitlab::AppLogger).to receive(:info).with(/PAT CREATION: created_by: '#{current_user.username}', created_for: '#{user.username}', token_id: '\d+'/)

      subject
    end
  end

  shared_examples_for 'an unsuccessfully created token' do
    it { expect(subject.success?).to be false }
    it { expect(subject.message).to eq('Not permitted to create') }
    it { expect(token).to be_nil }
  end

  describe '#execute' do
    subject { service.execute }

    let(:current_user) { create(:user) }
    let(:user) { create(:user) }
    let(:params) { { name: 'Test token', impersonation: false, scopes: [:api], expires_at: Date.today + 1.month } }
    let(:service) { described_class.new(current_user: current_user, target_user: user, params: params) }
    let(:token) { subject.payload[:personal_access_token] }

    context 'when current_user is an administrator' do
      let(:current_user) { create(:admin) }

      context 'when admin mode is enabled', :enable_admin_mode do
        it_behaves_like 'a successfully created token'
      end

      context 'when admin mode is disabled' do
        it_behaves_like 'an unsuccessfully created token'
      end
    end

    context 'when current_user is not an administrator' do
      context 'target_user is not the same as current_user' do
        it_behaves_like 'an unsuccessfully created token'
      end

      context 'target_user is same as current_user' do
        let(:current_user) { user }

        it_behaves_like 'a successfully created token'
      end
    end
  end
end
