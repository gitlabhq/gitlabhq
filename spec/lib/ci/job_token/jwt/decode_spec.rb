# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::JobToken::Jwt::Decode, feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:build) { create(:ci_build, :running) }
  let_it_be(:another_object) { create(:user) }
  let_it_be(:key) { OpenSSL::PKey::RSA.generate(2048) }

  shared_examples 'tracks an error and returns nil' do |error_type|
    it 'tracks an error and returns nil' do
      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(instance_of(error_type))
      expect(result).to be_nil
    end
  end

  before do
    allow(::Ci::JobToken::Jwt::Encode).to receive(:key).and_return(key)
    allow(described_class).to receive(:key).and_return(key)
  end

  describe '#job', :freeze_time do
    let(:token) { build.token }

    subject(:result) { described_class.new(token).job }

    it { is_expected.to eq(build) }

    context 'when the token is invalid' do
      where(:token) do
        [nil, '', SecureRandom.uuid]
      end

      with_them do
        it_behaves_like 'tracks an error and returns nil', JWT::DecodeError
      end
    end

    context 'when the token subject is not a Ci::Build' do
      let(:token) { ::Gitlab::Authz::Token::Encode.new(another_object).encode }

      before do
        allow(::Gitlab::Authz::Token::Encode).to receive_messages(key: key, expected_type: another_object.class)
      end

      it_behaves_like 'tracks an error and returns nil', Gitlab::Graphql::Errors::ArgumentError
    end

    context 'when the token signature is invalid' do
      let(:token) do
        jwt = build.token
        header, encoded_body, signature = jwt.split('.', 3)
        body = Gitlab::Json.parse(Base64.decode64(encoded_body))
        body['sub'] = another_object.to_global_id.to_s
        [header, Base64.encode64(Gitlab::Json.generate(body)), signature].join('.')
      end

      it_behaves_like 'tracks an error and returns nil', JWT::VerificationError
    end

    context 'when the token is expired' do
      before do
        token
        travel_to 2.minutes.from_now + Ci::JobToken::Jwt::Encode::LEEWAY
      end

      it_behaves_like 'tracks an error and returns nil', JWT::ExpiredSignature
    end
  end
end
