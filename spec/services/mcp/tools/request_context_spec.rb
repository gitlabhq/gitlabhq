# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::RequestContext, feature_category: :mcp_server do
  let(:user) { build_stubbed(:user) }

  it 'holds the user, the access token, and the request' do
    token = build_stubbed(:personal_access_token)
    request = instance_double(Rack::Request)

    context = described_class.new(current_user: user, access_token: token, request: request)

    expect(context).to have_attributes(current_user: user, access_token: token, request: request)
  end

  it 'defaults the access token and the request to nil' do
    expect(described_class.new(current_user: user)).to have_attributes(access_token: nil, request: nil)
  end

  it 'rejects a missing user' do
    expect { described_class.new(current_user: nil) }.to raise_error(ArgumentError, 'current_user must be a User')
  end
end
