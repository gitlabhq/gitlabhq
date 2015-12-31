require 'spec_helper'

describe Gitlab::GithubImport::Client, lib: true do
  let(:token) { '123456' }
  let(:client) { Gitlab::GithubImport::Client.new(token) }

  before do
    github_provider = OpenStruct.new(app_id: "asd123", app_secret: "asd123", name: "github", args: { "client_options" => {} })
    allow(Gitlab.config.omniauth).to receive(:providers).and_return([github_provider])
  end

  it 'all OAuth2 client options are symbols' do
    client.client.options.keys.each do |key|
      expect(key).to be_kind_of(Symbol)
    end
  end
end
