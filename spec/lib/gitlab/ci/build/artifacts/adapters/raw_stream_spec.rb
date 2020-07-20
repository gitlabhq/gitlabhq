# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Artifacts::Adapters::RawStream do
  describe '#initialize' do
    context 'when stream is passed' do
      let(:stream) { File.open(expand_fixture_path('junit/junit.xml'), 'rb') }

      it 'initialized' do
        expect { described_class.new(stream) }.not_to raise_error
      end
    end

    context 'when stream is not passed' do
      let(:stream) { nil }

      it 'raises an error' do
        expect { described_class.new(stream) }.to raise_error(described_class::InvalidStreamError)
      end
    end
  end

  describe '#each_blob' do
    let(:adapter) { described_class.new(stream) }

    context 'when file is not empty' do
      let(:stream) { File.open(expand_fixture_path('junit/junit.xml'), 'rb') }

      it 'iterates content' do
        expect { |b| adapter.each_blob(&b) }
          .to yield_with_args(fixture_file('junit/junit.xml'), 'raw')
      end
    end

    context 'when file is empty' do
      let(:stream) { Tempfile.new }

      after do
        stream.unlink
      end

      it 'does not iterate content' do
        expect { |b| adapter.each_blob(&b) }
          .not_to yield_control
      end
    end
  end
end
