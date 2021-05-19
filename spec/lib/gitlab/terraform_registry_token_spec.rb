# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::TerraformRegistryToken do
  let_it_be(:user) { create(:user) }

  describe '.from_token' do
    let(:jwt_token) { described_class.from_token(token) }

    subject { described_class.decode(jwt_token.encoded) }

    context 'with a deploy token' do
      let(:deploy_token) { create(:deploy_token, username: 'deployer') }
      let(:token) { deploy_token }

      it 'returns the correct token' do
        expect(subject['token']).to eq jwt_token['token']
      end
    end

    context 'with a job' do
      let_it_be(:job) { create(:ci_build) }

      let(:token) { job }

      it 'returns the correct token' do
        expect(subject['token']).to eq jwt_token['token']
      end
    end

    context 'with a personal access token' do
      let(:token) { create(:personal_access_token) }

      it 'returns the correct token' do
        expect(subject['token']).to eq jwt_token['token']
      end
    end
  end

  it_behaves_like 'a gitlab jwt token'
end
