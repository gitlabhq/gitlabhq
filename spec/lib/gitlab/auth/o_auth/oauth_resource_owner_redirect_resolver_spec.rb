# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::OAuth::OauthResourceOwnerRedirectResolver, feature_category: :system_access do
  let(:resolver) { described_class.new(namespace_path) }
  let(:namespace_path) { nil }
  let(:group) { create(:group) }

  describe '#resolve_redirect_url' do
    subject(:resolve_redirect_url) { resolver.resolve_redirect_url }

    before do
      allow(resolver).to receive(:new_user_session_url).and_return('/login')
    end

    context 'with any namespace path' do
      let(:namespace_path) { group.full_path }

      it 'returns new_user_session_url' do
        expect(resolver).to receive(:new_user_session_url)
        expect(resolve_redirect_url).to eq('/login')
      end
    end

    context 'with nil namespace path' do
      let(:namespace_path) { nil }

      it 'returns new_user_session_url' do
        expect(resolve_redirect_url).to eq('/login')
      end
    end
  end
end
