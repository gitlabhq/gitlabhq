require 'spec_helper'
require_relative '../../config/initializers/doorkeeper'

describe Doorkeeper.configuration do
  describe '#default_scopes' do
    it 'matches Gitlab::Auth::DEFAULT_SCOPES' do
      expect(subject.default_scopes).to eq Gitlab::Auth::DEFAULT_SCOPES
    end
  end

  describe '#optional_scopes' do
    it 'matches Gitlab::Auth.optional_scopes' do
      expect(subject.optional_scopes).to eq Gitlab::Auth.optional_scopes - Gitlab::Auth::REGISTRY_SCOPES
    end
  end

  describe '#resource_owner_authenticator' do
    subject { controller.instance_exec(&Doorkeeper.configuration.authenticate_resource_owner) }

    let(:controller) { double }

    before do
      allow(controller).to receive(:current_user).and_return(current_user)
      allow(controller).to receive(:session).and_return({})
      allow(controller).to receive(:request).and_return(OpenStruct.new(fullpath: '/return-path'))
      allow(controller).to receive(:redirect_to)
      allow(controller).to receive(:new_user_session_url).and_return('/login')
    end

    context 'with a user present' do
      let(:current_user) { create(:user) }

      it 'returns the user' do
        expect(subject).to eq current_user
      end

      it 'does not redirect' do
        expect(controller).not_to receive(:redirect_to)

        subject
      end

      it 'does not store the return path' do
        subject

        expect(controller.session).not_to include :user_return_to
      end
    end

    context 'without a user present' do
      let(:current_user) { nil }

      # NOTE: this is required for doorkeeper-openid_connect
      it 'returns nil' do
        expect(subject).to eq nil
      end

      it 'redirects to the login form' do
        expect(controller).to receive(:redirect_to).with('/login')

        subject
      end

      it 'stores the return path' do
        subject

        expect(controller.session[:user_return_to]).to eq '/return-path'
      end
    end
  end
end
