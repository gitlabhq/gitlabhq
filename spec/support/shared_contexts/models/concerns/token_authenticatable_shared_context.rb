# frozen_string_literal: true

RSpec.shared_context 'with token authenticatable routable token context' do
  let(:random_bytes) { 'a' * Authn::TokenField::Generator::RoutableToken::RANDOM_BYTES_LENGTH }
  let(:devise_token) { 'devise-token' }

  before do
    allow(Authn::TokenField::Generator::RoutableToken)
      .to receive(:random_bytes).with(Authn::TokenField::Generator::RoutableToken::RANDOM_BYTES_LENGTH)
      .and_return(random_bytes)
    allow(Devise).to receive(:friendly_token).and_return(devise_token)
    stub_config(cell: { enabled: true, id: 1 })
  end
end
