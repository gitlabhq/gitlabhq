require 'spec_helper'

describe Gitlab::StorageCheck::OptionParser do
  describe '.parse!' do
    it 'assigns all options' do
      args = %w(--target unix://tmp/hello/world.sock --token thetoken --interval 42)

      options = described_class.parse!(args)

      expect(options.token).to eq('thetoken')
      expect(options.interval).to eq(42)
      expect(options.target).to eq('unix://tmp/hello/world.sock')
    end

    it 'requires the interval to be a number' do
      args = %w(--target unix://tmp/hello/world.sock --interval fortytwo)

      expect { described_class.parse!(args) }.to raise_error(OptionParser::InvalidArgument)
    end

    it 'raises an error if the scheme is not included' do
      args = %w(--target tmp/hello/world.sock)

      expect { described_class.parse!(args) }.to raise_error(OptionParser::InvalidArgument)
    end

    it 'raises an error if both socket and host are missing' do
      expect { described_class.parse!([]) }.to raise_error(OptionParser::InvalidArgument)
    end
  end
end
