# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GlId, feature_category: :source_code_management do
  describe '.gl_id' do
    context 'when actor is a User' do
      let_it_be(:user) { create(:user) }

      it 'returns user-{id}' do
        expect(described_class.gl_id(user)).to eq("user-#{user.id}")
      end
    end

    context 'when actor is a DeployToken' do
      let_it_be(:deploy_token) { create(:deploy_token) }

      it 'returns deploy-token-{id}' do
        expect(described_class.gl_id(deploy_token)).to eq("deploy-token-#{deploy_token.id}")
      end
    end

    context 'when actor is nil' do
      it 'returns an empty string' do
        expect(described_class.gl_id(nil)).to eq('')
      end
    end

    context 'when actor is an unrecognized type' do
      it 'returns an empty string' do
        expect(described_class.gl_id('unknown')).to eq('')
      end
    end
  end
end
