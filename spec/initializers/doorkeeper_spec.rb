# frozen_string_literal: true

require 'spec_helper'
require_relative '../../config/initializers/doorkeeper'

RSpec.describe Doorkeeper.configuration do
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
    let(:base_request_params) { {} }
    let(:mock_request) do
      instance_double(ActionDispatch::Request,
        'request',
        fullpath: '/return-path',
        query_parameters: base_request_params
      )
    end

    let(:resolver) { instance_double(Gitlab::Auth::OAuth::OauthResourceOwnerRedirectResolver) }

    before do
      allow(controller).to receive_messages(
        current_user: current_user,
        session: {},
        request: mock_request
      )
      allow(controller).to receive(:redirect_to)
      allow(::Gitlab::Auth::OAuth::OauthResourceOwnerRedirectResolver)
        .to receive(:new)
        .with(any_args)
        .and_return(resolver)
      allow(resolver).to receive(:resolve_redirect_url).and_return('/login')
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
