require 'spec_helper'

describe Gitlab::Sherlock::FileSample do
  let(:sample) { described_class.new(__FILE__, [], 150.4, 2) }

  describe '#id' do
    it 'returns the ID' do
      expect(sample.id).to be_an_instance_of(String)
    end
  end

  describe '#file' do
    it 'returns the file path' do
      expect(sample.file).to eq(__FILE__)
    end
  end

  describe '#line_samples' do
    it 'returns the line samples' do
      expect(sample.line_samples).to eq([])
    end
  end

  describe '#events' do
    it 'returns the total number of events' do
      expect(sample.events).to eq(2)
    end
  end

  describe '#duration' do
    it 'returns the total execution time' do
      expect(sample.duration).to eq(150.4)
    end
  end

  describe '#relative_path' do
    it 'returns the relative path' do
      expect(sample.relative_path)
        .to eq('spec/lib/gitlab/sherlock/file_sample_spec.rb')
    end
  end

  describe '#to_param' do
    it 'returns the sample ID' do
      expect(sample.to_param).to eq(sample.id)
    end
  end

  describe '#source' do
    it 'returns the contents of the file' do
      expect(sample.source).to eq(File.read(__FILE__))
    end
  end
end
