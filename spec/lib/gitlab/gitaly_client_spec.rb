require 'spec_helper'

describe Gitlab::GitalyClient, lib: true do
  describe '.new_channel' do
    context 'when passed a UNIX socket address' do
      it 'passes the address as-is to GRPC::Core::Channel initializer' do
        address = 'unix:/tmp/gitaly.sock'

        expect(GRPC::Core::Channel).to receive(:new).with(address, any_args)

        described_class.new_channel(address)
      end
    end

    context 'when passed a TCP address' do
      it 'strips tcp:// prefix before passing it to GRPC::Core::Channel initializer' do
        address = 'localhost:9876'
        prefixed_address = "tcp://#{address}"

        expect(GRPC::Core::Channel).to receive(:new).with(address, any_args)

        described_class.new_channel(prefixed_address)
      end
    end
  end
end
