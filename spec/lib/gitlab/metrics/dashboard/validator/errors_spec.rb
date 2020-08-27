# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::Validator::Errors do
  describe Gitlab::Metrics::Dashboard::Validator::Errors::SchemaValidationError do
    context 'empty error hash' do
      let(:error_hash) { {} }

      it 'uses default error message' do
        expect(described_class.new(error_hash).message).to eq('Dashboard failed schema validation')
      end
    end

    context 'formatted message' do
      subject { described_class.new(error_hash).message }

      let(:error_hash) do
        {
          'data'         => 'property_name',
          'data_pointer' => pointer,
          'type'         => type,
          'schema'       => 'schema',
          'details'      => details
        }
      end

      context 'for root object' do
        let(:pointer) { '' }

        context 'when required keys are missing' do
          let(:type) { 'required' }
          let(:details) { { 'missing_keys' => ['one'] } }

          it { is_expected.to eq 'root is missing required keys: one' }
        end

        context 'when there is type mismatch' do
          %w(null string boolean integer number array object).each do |expected_type|
            context "on type: #{expected_type}" do
              let(:type) { expected_type }
              let(:details) { nil }

              it { is_expected.to eq "'property_name' at root is not of type: #{expected_type}" }
            end
          end
        end
      end

      context 'for nested object' do
        let(:pointer) { '/nested_objects/0' }

        context 'when required keys are missing' do
          let(:type) { 'required' }
          let(:details) { { 'missing_keys' => ['two'] } }

          it { is_expected.to eq '/nested_objects/0 is missing required keys: two' }
        end

        context 'when there is type mismatch' do
          %w(null string boolean integer number array object).each do |expected_type|
            context "on type: #{expected_type}" do
              let(:type) { expected_type }
              let(:details) { nil }

              it { is_expected.to eq "'property_name' at /nested_objects/0 is not of type: #{expected_type}" }
            end
          end
        end

        context 'when data does not match pattern' do
          let(:type) { 'pattern' }
          let(:error_hash) do
            {
              'data'         => 'property_name',
              'data_pointer' => pointer,
              'type'         => type,
              'schema'       => { 'pattern' => 'aa.*' }
            }
          end

          it { is_expected.to eq "'property_name' at /nested_objects/0 does not match pattern: aa.*" }
        end

        context 'when data does not match format' do
          let(:type) { 'format' }
          let(:error_hash) do
            {
              'data'         => 'property_name',
              'data_pointer' => pointer,
              'type'         => type,
              'schema'       => { 'format' => 'date-time' }
            }
          end

          it { is_expected.to eq "'property_name' at /nested_objects/0 does not match format: date-time" }
        end

        context 'when data is not const' do
          let(:type) { 'const' }
          let(:error_hash) do
            {
              'data'         => 'property_name',
              'data_pointer' => pointer,
              'type'         => type,
              'schema'       => { 'const' => 'one' }
            }
          end

          it { is_expected.to eq "'property_name' at /nested_objects/0 is not: \"one\"" }
        end

        context 'when data is not included in enum' do
          let(:type) { 'enum' }
          let(:error_hash) do
            {
              'data'         => 'property_name',
              'data_pointer' => pointer,
              'type'         => type,
              'schema'       => { 'enum' => %w(one two) }
            }
          end

          it { is_expected.to eq "'property_name' at /nested_objects/0 is not one of: [\"one\", \"two\"]" }
        end

        context 'when data is not included in enum' do
          let(:type) { 'unknown' }
          let(:error_hash) do
            {
              'data'         => 'property_name',
              'data_pointer' => pointer,
              'type'         => type,
              'schema'       => 'schema'
            }
          end

          it { is_expected.to eq "'property_name' at /nested_objects/0 is invalid: error_type=unknown" }
        end
      end
    end
  end

  describe Gitlab::Metrics::Dashboard::Validator::Errors::DuplicateMetricIds do
    it 'has custom error message' do
      expect(described_class.new.message).to eq('metric_id must be unique across a project')
    end
  end
end
