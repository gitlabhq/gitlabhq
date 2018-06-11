require 'spec_helper'
require 'google/apis/core/base_service'

describe 'Google::Apis::ClientOptions' do
  let(:http_client) { Google::Apis::Core::BaseService.new('https://www.googleapis.com/', 'storage/v1/').send(:new_client) }

  it 'initializes a http client with specified options' do
    expect(http_client.connect_timeout).to eq(1200)
    expect(http_client.receive_timeout).to eq(1200)
    expect(http_client.send_timeout).to eq(1200)
  end
end
