require 'spec_helper'

describe Gitlab::GitlabImport::Client, lib: true do
  let(:token) { '123456' }
  let(:client) { Gitlab::GitlabImport::Client.new(token) }

  before do
    Gitlab.config.omniauth.providers << OpenStruct.new(app_id: "asd123", app_secret: "asd123", name: "gitlab")
  end

  it 'all OAuth2 client options are symbols' do
    client.client.options.keys.each do |key|
      expect(key).to be_kind_of(Symbol)
    end
  end
end
