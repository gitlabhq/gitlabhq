# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Fog::Storage::GoogleXML::File', :fog_requests do
  let(:storage) do
    Fog.mock!
    Fog::Storage.new(
      google_storage_access_key_id: "asdf",
      google_storage_secret_access_key: "asdf",
      provider: "Google"
    )
  end

  let(:file) do
    # rubocop:disable Rails/SaveBang
    directory = storage.directories.create(key: 'data')
    directory.files.create(
      body: 'Hello World!',
      key: 'hello_world.txt'
    )
    # rubocop:enable Rails/SaveBang
  end

  it 'delegates to #get_https_url' do
    expect(file.url(Time.now)).to start_with("https://")
  end
end
