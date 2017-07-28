require 'spec_helper'

describe Gitlab::GitlabImport::Client do
  include ImportSpecHelper

  let(:token) { '123456' }
  let(:client) { described_class.new(token) }

  before do
    stub_omniauth_provider('gitlab')
  end

  it 'all OAuth2 client options are symbols' do
    client.client.options.keys.each do |key|
      expect(key).to be_kind_of(Symbol)
    end
  end
end
