# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::OAuth::OauthResourceOwnerRedirectResolver, feature_category: :system_access do
  let(:resolver) { described_class.new(request, session) }
  let(:request) { instance_double(ActionDispatch::Request) }
  let(:session) { {} }
  let(:group) { create(:group) }

  describe '#resolve_redirect_url' do
    subject(:resolve_redirect_url) { resolver.resolve_redirect_url }

    before do
      allow(resolver).to receive(:new_user_session_url).and_return('/login')
    end

    context 'with any namespace id' do
      let(:root_namespace_id) { group.id }

      before do
        allow(request).to receive(:query_parameters).and_return({ 'root_namespace_id' => root_namespace_id })
      end

      it 'returns new_user_session_url' do
        expect(resolver).to receive(:new_user_session_url)
        expect(resolve_redirect_url).to eq('/login')
      end
    end

    context 'with nil namespace id' do
      let(:root_namespace_id) { nil }

      before do
        allow(request).to receive(:query_parameters).and_return({ 'root_namespace_id' => root_namespace_id })
      end

      it 'returns new_user_session_url' do
        expect(resolve_redirect_url).to eq('/login')
      end
    end
  end
end
