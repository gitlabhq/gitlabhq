require 'spec_helper'

describe OmniAuth::Strategies::Jwt do
  include Rack::Test::Methods
  include DeviseHelpers

  context '.decoded' do
    let(:strategy) { described_class.new({}) }
    let(:timestamp) { Time.now.to_i }
    let(:jwt_config) { Devise.omniauth_configs[:jwt] }
    let(:key) { JWT.encode(claims, jwt_config.strategy.secret) }

    let(:claims) do
      {
        id: 123,
        name: "user_example",
        email: "user@example.com",
        iat: timestamp
      }
    end

    before do
      allow_any_instance_of(OmniAuth::Strategy).to receive(:options).and_return(jwt_config.strategy)
      allow_any_instance_of(Rack::Request).to receive(:params).and_return({ 'jwt' => key })
    end

    it 'decodes the user information' do
      result = strategy.decoded

      expect(result["id"]).to eq(123)
      expect(result["name"]).to eq("user_example")
      expect(result["email"]).to eq("user@example.com")
      expect(result["iat"]).to eq(timestamp)
    end

    context 'required claims is missing' do
      let(:claims) do
        {
          id: 123,
          email: "user@example.com",
          iat: timestamp
        }
      end

      it 'raises error' do
        expect { strategy.decoded }.to raise_error(OmniAuth::Strategies::JWT::ClaimInvalid)
      end
    end

    context 'when valid_within is specified but iat attribute is missing in response' do
      let(:claims) do
        {
          id: 123,
          name: "user_example",
          email: "user@example.com"
        }
      end

      before do
        jwt_config.strategy.valid_within = Time.now.to_i
      end

      it 'raises error' do
        expect { strategy.decoded }.to raise_error(OmniAuth::Strategies::JWT::ClaimInvalid)
      end
    end

    context 'when timestamp claim is too skewed from present' do
      let(:claims) do
        {
          id: 123,
          name: "user_example",
          email: "user@example.com",
          iat: timestamp - 10.minutes.to_i
        }
      end

      before do
        jwt_config.strategy.valid_within = 2.seconds
      end

      it 'raises error' do
        expect { strategy.decoded }.to raise_error(OmniAuth::Strategies::JWT::ClaimInvalid)
      end
    end
  end
end
