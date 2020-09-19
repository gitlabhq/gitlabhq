# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Artifactable do
  let(:ci_job_artifact) { build(:ci_job_artifact) }

  describe 'artifact properties are included' do
    context 'when enum is defined' do
      subject { ci_job_artifact }

      it { is_expected.to define_enum_for(:file_format).with_values(raw: 1, zip: 2, gzip: 3).with_suffix }
    end

    context 'when const is defined' do
      subject { ci_job_artifact.class }

      it { is_expected.to be_const_defined(:FILE_FORMAT_ADAPTERS) }
    end
  end

  describe '#each_blob' do
    context 'when file format is gzip' do
      context 'when gzip file contains one file' do
        let(:artifact) { build(:ci_job_artifact, :junit) }

        it 'iterates blob once' do
          expect { |b| artifact.each_blob(&b) }.to yield_control.once
        end
      end

      context 'when gzip file contains three files' do
        let(:artifact) { build(:ci_job_artifact, :junit_with_three_testsuites) }

        it 'iterates blob three times' do
          expect { |b| artifact.each_blob(&b) }.to yield_control.exactly(3).times
        end
      end
    end

    context 'when file format is raw' do
      let(:artifact) { build(:ci_job_artifact, :codequality, file_format: :raw) }

      it 'iterates blob once' do
        expect { |b| artifact.each_blob(&b) }.to yield_control.once
      end
    end

    context 'when there are no adapters for the file format' do
      let(:artifact) { build(:ci_job_artifact, :junit, file_format: :zip) }

      it 'raises an error' do
        expect { |b| artifact.each_blob(&b) }.to raise_error(described_class::NotSupportedAdapterError)
      end
    end
  end
end
