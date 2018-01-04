require 'spec_helper'

describe Gitlab::StorageCheck::GitlabCaller do
  let(:options) { Gitlab::StorageCheck::Options.new('unix://tmp/socket.sock', nil, nil, false) }
  subject(:gitlab_caller) { described_class.new(options) }

  describe '#call!' do
    context 'when a socket is given' do
      it 'calls a socket' do
        fake_connection = double
        expect(fake_connection).to receive(:post)
        expect(Excon).to receive(:new).with('unix://tmp/socket.sock', socket: "tmp/socket.sock") { fake_connection }

        gitlab_caller.call!
      end
    end

    context 'when a host is given' do
      let(:options) { Gitlab::StorageCheck::Options.new('http://localhost:8080', nil, nil, false) }

      it 'it calls a http response' do
        fake_connection = double
        expect(Excon).to receive(:new).with('http://localhost:8080', socket: nil) { fake_connection }
        expect(fake_connection).to receive(:post)

        gitlab_caller.call!
      end
    end
  end

  describe '#headers' do
    it 'Adds the JSON header' do
      headers = gitlab_caller.headers

      expect(headers['Content-Type']).to eq('application/json')
    end

    context 'when a token was provided' do
      let(:options) { Gitlab::StorageCheck::Options.new('unix://tmp/socket.sock', 'atoken', nil, false) }

      it 'adds it to the headers' do
        expect(gitlab_caller.headers['TOKEN']).to eq('atoken')
      end
    end
  end
end
