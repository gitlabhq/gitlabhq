require 'spec_helper'

describe Gitlab::Geo::RemoteNode do
  subject { described_class.new }
  let(:access_token) { FactoryGirl.create(:doorkeeper_access_token).token }
  let(:user) { FactoryGirl.build(:user) }

  before(:each) do
    allow(subject).to receive(:primary_node_url) { 'http://localhost:3001/' }
    allow(described_class).to receive(:get) { response }
  end

  describe '#authenticate' do
    let(:response) { double }

    context 'on success' do
      it 'returns hashed user data' do
        allow(response).to receive(:code) { 200 }
        allow(response).to receive(:parsed_response) { user.to_json }

        subject.authenticate(access_token)
      end
    end

    context 'on invalid token' do
      it 'raises exception' do
        allow(response).to receive(:code) { 401 }

        expect { subject.authenticate(access_token) }.to raise_error(Gitlab::Geo::RemoteNode::InvalidCredentialsError)
      end
    end
  end
end
