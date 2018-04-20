require 'spec_helper'

describe '/-/acme-challenge/' do
  describe 'GET /:domain/:token' do
    context 'when the domain exists with matching acme token' do
      before do
        create(:pages_domain,
               domain: 'mydomain.com',
               acme_challenge_token: 'the-token',
               acme_challenge_response: 'the-token.the-rest-of-the-content'
              )
      end

      it 'returns the challenge content for the domain' do
        get '/-/acme-challenge/mydomain.com/the-token'

        expect(response).to have_gitlab_http_status 200
        expect(response.body).to eq('the-token.the-rest-of-the-content')
      end
    end

    context 'when the token does not match' do
    end

    context 'when the domain is not verified' do
    end

    context 'when the domain does not exist' do
    end
  end
end
