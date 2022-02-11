# rubocop:disable Style/FrozenStringLiteralComment
require 'spec_helper'

RSpec.describe Gitlab::BufferedIo do
  describe '#readuntil' do
    let(:never_ending_tcp_socket) do
      Class.new do
        def initialize(*_)
          @read_counter = 0
        end

        def setsockopt(*_); end

        def closed?
          false
        end

        def close
          true
        end

        def to_io
          StringIO.new('Hello World!')
        end

        def write_nonblock(data, *_)
          data.size
        end

        def read_nonblock(buffer_size, *_)
          sleep 0.01
          @read_counter += 1

          raise 'Test did not raise HeaderReadTimeout' if @read_counter > 10

          'H' * buffer_size
        end
      end
    end

    before do
      stub_const('Gitlab::BufferedIo::HEADER_READ_TIMEOUT', 0.1)
    end

    subject(:readuntil) do
      Gitlab::BufferedIo.new(never_ending_tcp_socket.new).readuntil('a')
    end

    it 'raises a timeout error' do
      expect { readuntil }.to raise_error(Gitlab::HTTP::HeaderReadTimeout, /Request timed out after reading headers for 0\.[0-9]+ seconds/)
    end
  end
end
# rubocop:enable Style/FrozenStringLiteralComment
