require 'spec_helper'

describe Gitlab::BitbucketImport::Client do
  let(:token) { '123456' }
  let(:secret) { 'secret' }
  let(:client) { Gitlab::BitbucketImport::Client.new(token, secret) }

  before do
    Gitlab.config.omniauth.providers << OpenStruct.new(app_id: "asd123", app_secret: "asd123", name: "bitbucket")
  end

  it 'all OAuth client options are symbols' do
    client.consumer.options.keys.each do |key|
      expect(key).to be_kind_of(Symbol)
    end
  end
end
