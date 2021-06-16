# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddDeployTokenTypeToDeployTokens do
  let(:deploy_tokens) { table(:deploy_tokens) }
  let(:deploy_token) do
    deploy_tokens.create!(name: 'token_test',
                         username: 'gitlab+deploy-token-1',
                         token_encrypted: 'dr8rPXwM+Mbs2p3Bg1+gpnXqrnH/wu6vaHdcc7A3isPR67WB',
                         read_repository: true,
                         expires_at: Time.now + 1.year)
  end

  it 'updates the deploy_token_type column to 2' do
    expect(deploy_token).not_to respond_to(:deploy_token_type)

    migrate!

    deploy_token.reload
    expect(deploy_token.deploy_token_type).to eq(2)
  end
end
