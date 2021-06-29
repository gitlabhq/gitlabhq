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

    shared_examples 'returning' do |status:, message:|
      it "returns #{message}", :aggregate_failures do
        expect(subject[:http_status]).to eq(status)
        expect(subject[:message]).to eq(message)
      end
    end

    context 'dependency proxy is not enabled' do
      before do
        stub_config(dependency_proxy: { enabled: false })
      end

      it_behaves_like 'returning', status: 404, message: 'dependency proxy not enabled'
    end

    context 'without a user' do
      let(:user) { nil }

      it_behaves_like 'returning', status: 403, message: 'access forbidden'
    end

    context 'with a deploy token as user' do
      let_it_be(:user) { create(:deploy_token) }

      it_behaves_like 'returning', status: 403, message: 'access forbidden'
    end

    context 'with a user' do
      it 'returns a token' do
        expect(subject[:token]).not_to be_nil
      end
    end
  end
end
