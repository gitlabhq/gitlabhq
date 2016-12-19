require 'spec_helper'

describe Mattermost::Command do
  let(:session) { double("session") }
  let(:hash) { { 'token' => 'token' } }

  describe '.create' do
    before do
      allow(session).to receive(:post).and_return(hash)
      allow(hash).to receive(:parsed_response).and_return(hash)
    end

    context 'with access' do
      it 'gets the teams' do
        expect(session).to receive(:post)

        described_class.create(session, 'abc', url: 'http://trigger.com')
      end
    end

    context 'on an error' do

    end
  end
end
