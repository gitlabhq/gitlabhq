require 'spec_helper'

describe Gitlab::GitalyClient, lib: true do
  describe '.stub' do
    before { described_class.clear_stubs! }

    context 'when passed a UNIX socket address' do
      it 'passes the address as-is to GRPC' do
        address = 'unix:/tmp/gitaly.sock'
        allow(Gitlab.config.repositories).to receive(:storages).and_return({
          'default' => { 'gitaly_address' => address }
        })

        expect(Gitaly::Commit::Stub).to receive(:new).with(address, any_args)

        described_class.stub(:commit, 'default')
      end
    end

    context 'when passed a TCP address' do
      it 'strips tcp:// prefix before passing it to GRPC::Core::Channel initializer' do
        address = 'localhost:9876'
        prefixed_address = "tcp://#{address}"

        allow(Gitlab.config.repositories).to receive(:storages).and_return({
          'default' => { 'gitaly_address' => prefixed_address }
        })

        expect(Gitaly::Commit::Stub).to receive(:new).with(address, any_args)

        described_class.stub(:commit, 'default')
      end
    end
  end
end
