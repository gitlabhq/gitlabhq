# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Reports::CoverageReport, feature_category: :pipeline_composition do
  let(:entry) { described_class.new(config) }

  describe 'validations' do
    context 'when it is valid' do
      let(:config) { { coverage_format: 'cobertura', path: 'cobertura-coverage.xml' } }

      it { expect(entry).to be_valid }

      it { expect(entry.value).to eq(config) }
    end

    context 'when it is not a hash' do
      where(:config) { ['string', true, []] }

      with_them do
        it { expect(entry).not_to be_valid }

        it { expect(entry.errors).to include(/should be a hash/) }
      end
    end

    context 'with unsupported coverage format' do
      let(:config) { { coverage_format: 'anotherformat', path: 'anotherformat.xml' } }

      it { expect(entry).not_to be_valid }

      it { expect(entry.errors).to include(/format must be one of supported formats/) }
    end

    context 'with jacoco coverage format' do
      let(:config) { { coverage_format: 'jacoco', path: 'jacoco.xml' } }

      it { expect(entry).to be_valid }

      it { expect(entry.value).to eq(config) }
    end

    context 'without coverage format' do
      let(:config) { { path: 'cobertura-coverage.xml' } }

      it { expect(entry).not_to be_valid }

      it { expect(entry.errors).to include(/format can't be blank/) }
    end

    context 'without path' do
      let(:config) { { coverage_format: 'cobertura' } }

      it { expect(entry).not_to be_valid }

      it { expect(entry.errors).to include(/path can't be blank/) }
    end

    context 'with invalid path' do
      let(:config) { { coverage_format: 'cobertura', path: 123 } }

      it { expect(entry).not_to be_valid }

      it { expect(entry.errors).to include(/path should be a string/) }
    end

    context 'with unknown keys' do
      let(:config) { { coverage_format: 'cobertura', path: 'cobertura-coverage.xml', foo: :bar } }

      it { expect(entry).not_to be_valid }

      it { expect(entry.errors).to include(/contains unknown keys/) }
    end
  end
end
