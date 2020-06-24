# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Artifacts::Adapters::GzipStream do
  describe '#initialize' do
    context 'when stream is passed' do
      let(:stream) { File.open(expand_fixture_path('junit/junit.xml.gz'), 'rb') }

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

    context 'when stream is gzip file' do
      context 'when gzip file contains one file' do
        let(:stream) { File.open(expand_fixture_path('junit/junit.xml.gz'), 'rb') }

        it 'iterates content and file_name' do
          expect { |b| adapter.each_blob(&b) }
            .to yield_with_args(fixture_file('junit/junit.xml'), 'rspec.xml')
        end
      end

      context 'when gzip file contains three files' do
        let(:stream) { File.open(expand_fixture_path('junit/junit_with_three_testsuites.xml.gz'), 'rb') }

        it 'iterates content and file_name' do
          expect { |b| adapter.each_blob(&b) }
            .to yield_successive_args(
              [fixture_file('junit/junit_with_three_testsuites_1.xml'), 'rspec-3.xml'],
              [fixture_file('junit/junit_with_three_testsuites_2.xml'), 'rspec-1.xml'],
              [fixture_file('junit/junit_with_three_testsuites_3.xml'), 'rspec-2.xml'])
        end
      end
    end

    context 'when stream is zip file' do
      let(:stream) { File.open(expand_fixture_path('ci_build_artifacts.zip'), 'rb') }

      it 'raises an error' do
        expect { |b| adapter.each_blob(&b) }.to raise_error(described_class::InvalidStreamError)
      end
    end
  end
end
