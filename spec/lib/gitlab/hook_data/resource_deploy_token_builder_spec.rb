# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HookData::ResourceDeployTokenBuilder, feature_category: :continuous_delivery do
  let_it_be(:deploy_token) { create(:deploy_token) }

  let(:builder) { described_class.new(deploy_token) }

  describe '#build' do
    let(:data) { builder.build }

    it 'includes safe attributes' do
      expect(data.keys).to match_array(
        %w[
          id
          name
          username
          expires_at
          created_at
          revoked
          deploy_token_type
        ]
      )
    end
  end
end
