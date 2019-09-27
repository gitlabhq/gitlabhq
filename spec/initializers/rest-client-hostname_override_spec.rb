require 'spec_helper'

describe 'rest-client dns rebinding protection' do
  it_behaves_like 'a request using Gitlab::UrlBlocker' do
    let(:http_method) { :get }
    let(:url_blocked_error_class) { ArgumentError }

    def make_request(uri)
      RestClient.get(uri)
    end
  end
end
