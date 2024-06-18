# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::HandleIpSpoofAttackError do
  let(:spoof_error) { ActionDispatch::RemoteIp::IpSpoofAttackError.new('sensitive') }
  let(:standard_error) { StandardError.new('error') }
  let(:app) { ->(env) { env.is_a?(Exception) ? raise(env) : env } }

  subject(:middleware) { described_class.new(app) }

  it 'passes through the response from a valid upstream' do
    expect(middleware.call(:response)).to eq(:response)
  end

  it 'translates an ActionDispatch::IpSpoofAttackError to a 400 response' do
    expect(middleware.call(spoof_error))
      .to eq([400, { 'Content-Type' => 'text/plain' }, ['Bad Request']])
  end

  it 'passes through the exception raised by an invalid upstream' do
    expect { middleware.call(standard_error) }.to raise_error(standard_error)
  end
end
