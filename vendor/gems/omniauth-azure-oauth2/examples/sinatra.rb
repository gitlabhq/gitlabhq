$:.push File.dirname(__FILE__) + '/../lib'

require 'omniauth-azure-oauth2'
require 'sinatra'

class MyAzureProvider
  def self.client_id
    ENV['AZURE_CLIENT_ID']
  end

  def self.client_secret
    ENV['AZURE_CLIENT_SECRET']
  end

  def self.tenant_id
    ENV['AZURE_TENANT_ID']
  end

end

use Rack::Session::Cookie
use OmniAuth::Strategies::Azure, MyAzureProvider

get '/' do
  "<a href='/auth/azure_oauth2'>Log in with Azure</a>"
end

get '/auth/azure_oauth2/callback' do
  content_type 'text/plain'
  request.env['omniauth.auth'].inspect
end