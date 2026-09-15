# frozen_string_literal: true

RSpec.shared_context 'with token authenticatable routable token context' do
  let(:random_bytes) { 'a' * Authn::TokenField::Generator::RoutableToken::RANDOM_BYTES_LENGTH }
  let(:devise_token) { 'devise-token' }

  before do
    allow(Authn::TokenField::Generator::RoutableToken)
      .to receive(:random_bytes).with(Authn::TokenField::Generator::RoutableToken::RANDOM_BYTES_LENGTH)
      .and_return(random_bytes)
    allow(Devise).to receive(:friendly_token).and_return(devise_token)
    stub_config_cell({ enabled: true, id: 1 })
    # The cell is enabled here only to exercise routable token generation. Keep
    # factory-built records from claiming against a Topology Service that isn't running.
    allow(Cells::TransactionRecord).to receive(:current_transaction).and_return(nil)
  end
end
