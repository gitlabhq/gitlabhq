# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobToken::Middleware, feature_category: :secrets_management do
  using RSpec::Parameterized::TableSyntax

  describe '#call' do
    let(:middleware) { described_class.new(->(env) { env }) }
    let(:response_code) { 200 }
    let(:env) do
      [
        response_code,
        { 'Content-Type' => 'application/json' },
        { 'foo' => 'bar' }.to_json
      ]
    end

    it 'does not alter the response' do
      expect(middleware.call(env)).to eq(env)
    end

    where(:response_code, :schedule_log) do
      200 | true
      201 | true
      204 | true
      400 | false
      403 | false
      404 | false
      500 | false
    end

    with_them do
      it 'decides whether to schedule the authorization log based on the response code' do
        if schedule_log
          expect(Ci::JobToken::Authorization).to receive(:log_captures_async)
        else
          expect(Ci::JobToken::Authorization).not_to receive(:log_captures_async)
        end

        middleware.call(env)
      end
    end
  end
end
