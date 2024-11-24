# frozen_string_literal: true

require 'rails_helper'

describe Doorkeeper::OpenidConnect::OAuth::Authorization::Code do
  subject { Doorkeeper::OAuth::Authorization::Code.new pre_auth, resource_owner }

  let(:resource_owner) { create :user }
  let(:access_grant) { create :access_grant }
  let(:pre_auth) { double }
  let(:client) { double }

  describe '#issue_token' do
    before do
      allow(pre_auth).to receive(:client) { client }
      allow(pre_auth).to receive(:redirect_uri).and_return('redirect_uri')
      allow(pre_auth).to receive(:scopes).and_return('scopes')
      allow(pre_auth).to receive(:nonce).and_return('123456')
      allow(pre_auth).to receive(:code_challenge).and_return('987654')
      allow(pre_auth).to receive(:code_challenge_method).and_return('plain')
      allow(pre_auth).to receive(:custom_access_token_attributes).and_return({})
      allow(client).to receive(:id).and_return('client_id')

      allow(Doorkeeper::AccessGrant).to receive(:create!) { access_grant }
      allow(Doorkeeper::OpenidConnect::Request).to receive(:create!)
    end

    it 'stores the nonce' do
      subject.issue_token

      expect(Doorkeeper::OpenidConnect::Request).to have_received(:create!).with({
        access_grant: access_grant,
        nonce: '123456'
      })
    end

    it 'does not store the nonce if not present' do
      allow(pre_auth).to receive(:nonce).and_return(nil)
      subject.issue_token

      expect(Doorkeeper::OpenidConnect::Request).not_to have_received(:create!)
    end

    it 'does not store the nonce if blank' do
      allow(pre_auth).to receive(:nonce).and_return(' ')
      subject.issue_token

      expect(Doorkeeper::OpenidConnect::Request).not_to have_received(:create!)
    end

    it 'returns the created grant' do
      expect(subject.issue_token).to be_a Doorkeeper::AccessGrant
    end
  end
end
