# frozen_string_literal: true
require 'fast_spec_helper'

RSpec.describe Security::ReportSchemaVersionMatcher do
  let(:vendored_versions) { %w[14.0.0 14.0.1 14.0.2 14.1.0] }
  let(:version_finder) do
    described_class.new(
      report_declared_version: report_version,
      supported_versions: vendored_versions
    )
  end

  describe '#call' do
    subject { version_finder.call }

    context 'when minor version matches' do
      context 'and report schema patch version does not match any vendored schema versions' do
        context 'and report version is 14.1.1' do
          let(:report_version) { '14.1.1' }

          it 'returns 14.1.0' do
            expect(subject).to eq('14.1.0')
          end
        end

        context 'and report version is 14.0.32' do
          let(:report_version) { '14.0.32' }

          it 'returns 14.0.2' do
            expect(subject).to eq('14.0.2')
          end
        end
      end
    end

    context 'when report minor version does not match' do
      let(:report_version) { '14.2.1' }

      it 'does not return a version' do
        expect(subject).to be_nil
      end
    end
  end
end
