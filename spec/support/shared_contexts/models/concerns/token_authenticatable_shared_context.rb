# frozen_string_literal: true

RSpec.shared_context 'with token authenticatable routable token context' do
  let(:random_bytes) { 'a' * Authn::TokenField::Generator::RoutableToken::RANDOM_BYTES_LENGTH }
  let(:devise_token) { 'devise-token' }

  before do
    allow(Authn::TokenField::Generator::RoutableToken)
      .to receive(:random_bytes).with(Authn::TokenField::Generator::RoutableToken::RANDOM_BYTES_LENGTH)
      .and_return(random_bytes)
    allow(Devise).to receive(:friendly_token).and_return(devise_token)
    # We do not use stub_config because Gitlab.config.cell has other
    # values that we don't want to stub.
    allow(Gitlab.config.cell).to receive_messages(enabled: true, id: 1)

    # We're not stubbing everything behind this feature flag yet
    stub_feature_flags(cells_unique_claims: false)
  end
end
