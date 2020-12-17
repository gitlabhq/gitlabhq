# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Auth::DependencyProxyAuthenticationService do
  let_it_be(:user) { create(:user) }
  let(:service) { Auth::DependencyProxyAuthenticationService.new(nil, user) }

  before do
    stub_config(dependency_proxy: { enabled: true })
  end

  describe '#execute' do
    subject { service.execute(authentication_abilities: nil) }

    context 'dependency proxy is not enabled' do
      before do
        stub_config(dependency_proxy: { enabled: false })
      end

      it 'returns not found' do
        result = subject

        expect(result[:http_status]).to eq(404)
        expect(result[:message]).to eq('dependency proxy not enabled')
      end
    end

    context 'without a user' do
      let(:user) { nil }

      it 'returns forbidden' do
        result = subject

        expect(result[:http_status]).to eq(403)
        expect(result[:message]).to eq('access forbidden')
      end
    end

    context 'with a user' do
      it 'returns a token' do
        expect(subject[:token]).not_to be_nil
      end
    end
  end
end
