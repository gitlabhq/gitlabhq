require 'spec_helper'

describe Gitlab::GithubImport::Client do
  it '#authorize_url' do
    client = Gitlab::GithubImport::Client.new(nil)
    authorize_url = 'https://github.com/login/oauth/authorize?' +
                    'response_type=code&' +
                    'client_id=YOUR_APP_ID&' +
                    'redirect_uri=https%3A%2F%2Fapp.com&' +
                    'scope=repo%2C+user%2C+user%3Aemail'

    expect(client.authorize_url('https://app.com')).to eq(authorize_url)
  end
end
