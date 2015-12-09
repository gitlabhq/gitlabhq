require 'spec_helper'

describe Gitlab::Metrics do
  describe '.pool_size' do
    it 'returns a Fixnum' do
      expect(described_class.pool_size).to be_an_instance_of(Fixnum)
    end
  end

  describe '.timeout' do
    it 'returns a Fixnum' do
      expect(described_class.timeout).to be_an_instance_of(Fixnum)
    end
  end

  describe '.enabled?' do
    it 'returns a boolean' do
      expect([true, false].include?(described_class.enabled?)).to eq(true)
    end
  end

  describe '.hostname' do
    it 'returns a String containing the hostname' do
      expect(described_class.hostname).to eq(Socket.gethostname)
    end
  end

  describe '.last_relative_application_frame' do
    it 'returns an Array containing a file path and line number' do
      file, line = described_class.last_relative_application_frame

      expect(line).to eq(30)
      expect(file).to eq('spec/lib/gitlab/metrics_spec.rb')
    end
  end
end
