# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ml::IncrementVersionService, feature_category: :mlops do
  describe '#execute' do
    let(:increment_type) { nil }
    let(:finder) { described_class.new(version, increment_type) }

    context 'when given an invalid version format' do
      let(:version) { 'foo' }

      it 'raises an error' do
        expect { finder.execute }.to raise_error(RuntimeError, "Version must be in a valid SemVer format")
      end
    end

    context 'when given a non-semver version format' do
      let(:version) { 1 }

      it 'raises an error' do
        expect { finder.execute }.to raise_error(RuntimeError, "Version must be in a valid SemVer format")
      end
    end

    context 'when given an unsupported increment type' do
      let(:version) { '1.2.3' }
      let(:increment_type) { 'foo' }

      it 'raises an error' do
        expect do
          finder.execute
        end.to raise_error(RuntimeError, "Increment type must be one of :patch, :minor, or :major")
      end
    end

    context 'when valid inputs are provided' do
      using RSpec::Parameterized::TableSyntax

      where(:version, :increment_type, :result) do
        nil | nil | '1.0.0'
        '0.0.1' | nil | '0.0.2'
        '1.0.0' | nil | '1.0.1'
        '1.0.0' | :major | '2.0.0'
        '1.0.0' | :minor | '1.1.0'
        '1.0.0' | :patch | '1.0.1'
      end

      with_them do
        subject { finder.execute }

        it { is_expected.to eq(result) }
      end
    end
  end
end
