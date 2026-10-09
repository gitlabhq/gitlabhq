# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::RangedZipIo, feature_category: :mcp_server do
  let(:http_io) { instance_double(Gitlab::HttpIO, eof?: true, path: nil) }

  subject(:adapter) { described_class.new(http_io) }

  it 'answers eof by delegating to eof?' do
    expect(adapter.eof).to be(true)
  end

  it 'hides path so Zip::File cannot mistake the IO for a file on disk' do
    expect(adapter.respond_to?(:path)).to be(false)
  end

  describe '#seek' do
    it 'delegates an in-range seek' do
      allow(http_io).to receive(:seek).with(10, IO::SEEK_SET).and_return(10)

      expect(adapter.seek(10)).to eq(10)
    end

    it 'translates an out-of-range seek into the Errno::EINVAL a File raises, keeping the message' do
      allow(http_io).to receive(:seek).and_raise(RuntimeError, 'new position is outside of file')

      expect { adapter.seek(-64.kilobytes, IO::SEEK_END) }
        .to raise_error(Errno::EINVAL, /new position is outside of file/)
    end
  end
end
