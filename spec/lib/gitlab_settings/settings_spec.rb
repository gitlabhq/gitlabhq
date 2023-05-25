# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSettings::Settings, :aggregate_failures, feature_category: :shared do
  let(:config) do
    {
      section1: {
        config1: {
          value1: 1
        }
      }
    }
  end

  let(:source) { Tempfile.new('config.yaml') }

  before do
    File.write(source, config.to_yaml)
  end

  subject(:settings) { described_class.new(source.path, 'section1') }

  describe '#initialize' do
    it 'requires a source' do
      expect { described_class.new('', '') }
        .to raise_error(ArgumentError, 'config source is required')
    end

    it 'requires a section' do
      expect { described_class.new(source, '') }
        .to raise_error(ArgumentError, 'config section is required')
    end

    it 'sets encodings' do
      expect(Encoding).to receive(:default_external=).with(Encoding::UTF_8).and_call_original
      expect(Encoding).to receive(:default_internal=).with(Encoding::UTF_8).and_call_original

      File.write(source, { section1: { config1: { value1: 2 } } }.to_yaml)

      described_class.new(source, 'section1')
    end
  end

  describe '#reload!' do
    it 'reloads the config' do
      expect(settings.config1.value1).to eq(1)

      File.write(source, { section1: { config1: { value1: 2 } } }.to_yaml)

      # config doesn't change when source changes
      expect(settings.config1.value1).to eq(1)

      settings.reload!

      # config changes after reload! if source changed
      expect(settings.config1.value1).to eq(2)
    end
  end

  it 'loads the given section config' do
    expect(settings.config1.value1).to eq(1)
  end

  context 'on lazy loading' do
    it 'does not raise exception on initialization if source does not exists' do
      settings = nil

      expect { settings = described_class.new('/tmp/any/inexisting/file.yml', 'section1') }
        .not_to raise_error

      expect { settings['any key'] }
        .to raise_error(Errno::ENOENT)
    end
  end
end
