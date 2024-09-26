# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Sessions::RedisStore, feature_category: :cell do
  using RSpec::Parameterized::TableSyntax

  describe '#generate_sid' do
    let(:redis_store) do
      described_class.new(Rails.application, { session_cookie_token_prefix: session_cookie_token_prefix })
    end

    context 'when passing `session_cookie_token_prefix` in options' do
      where(:prefix, :calculated_prefix) do
        nil              | ''
        ''               | ''
        'random_prefix_' | 'random_prefix_-'
        '_random_prefix' | '_random_prefix-'
      end

      with_them do
        let(:session_cookie_token_prefix) { prefix }

        it 'generates sid that is prefixed with the configured prefix' do
          generated_sid = redis_store.generate_sid
          expect(generated_sid).to be_a Rack::Session::SessionId
          expect(generated_sid.public_id).to match(/^#{calculated_prefix}[a-z0-9]{32}$/)
        end
      end
    end

    context 'when not passing `session_cookie_token_prefix` in options' do
      let(:redis_store) { described_class.new(Rails.application) }

      it 'generates sid that is not prefixed' do
        generated_sid = redis_store.generate_sid
        expect(generated_sid).to be_a Rack::Session::SessionId
        expect(generated_sid.public_id).to match(/^[a-z0-9]{32}$/)
      end
    end
  end
end
