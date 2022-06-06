# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageMetricGenerator, :silence_stdout do
  let(:ce_temp_dir) { Dir.mktmpdir }
  let(:ee_temp_dir) { Dir.mktmpdir }
  let(:spec_ce_temp_dir) { Dir.mktmpdir }
  let(:spec_ee_temp_dir) { Dir.mktmpdir }
  let(:args) { ['CountFoo'] }
  let(:options) { { 'type' => 'generic' } }

  before do
    stub_const("#{described_class}::CE_DIR", ce_temp_dir)
    stub_const("#{described_class}::EE_DIR", ee_temp_dir)
    stub_const("#{described_class}::SPEC_CE_DIR", spec_ce_temp_dir)
    stub_const("#{described_class}::SPEC_EE_DIR", spec_ee_temp_dir)
  end

  after do
    FileUtils.rm_rf([ce_temp_dir, ee_temp_dir, spec_ce_temp_dir, spec_ee_temp_dir])
  end

  def expect_generated_file(directory, file_name, content)
    file_path = File.join(directory, file_name)
    file = File.read(file_path)

    expect(file).to eq(content)
  end

  describe 'Creating metric instrumentation files' do
    let(:sample_metric_dir) { 'lib/generators/gitlab/usage_metric_generator' }
    let(:generic_sample_metric) { fixture_file(File.join(sample_metric_dir, 'sample_generic_metric.rb')) }
    let(:database_sample_metric) { fixture_file(File.join(sample_metric_dir, 'sample_database_metric.rb')) }
    let(:numbers_sample_metric) { fixture_file(File.join(sample_metric_dir, 'sample_numbers_metric.rb')) }
    let(:sample_spec) { fixture_file(File.join(sample_metric_dir, 'sample_metric_test.rb')) }

    it 'creates CE metric instrumentation files using the template' do
      described_class.new(args, options).invoke_all

      expect_generated_file(ce_temp_dir, 'count_foo_metric.rb', generic_sample_metric)
      expect_generated_file(spec_ce_temp_dir, 'count_foo_metric_spec.rb', sample_spec)
    end

    context 'with EE flag true' do
      let(:options) { { 'type' => 'generic', 'ee' => true } }

      it 'creates EE metric instrumentation files using the template' do
        described_class.new(args, options).invoke_all

        expect_generated_file(ee_temp_dir, 'count_foo_metric.rb', generic_sample_metric)
        expect_generated_file(spec_ee_temp_dir, 'count_foo_metric_spec.rb', sample_spec)
      end
    end

    context 'for database type' do
      let(:options) { { 'type' => 'database', 'operation' => 'count' } }

      it 'creates the metric instrumentation file using the template' do
        described_class.new(args, options).invoke_all

        expect_generated_file(ce_temp_dir, 'count_foo_metric.rb', database_sample_metric)
        expect_generated_file(spec_ce_temp_dir, 'count_foo_metric_spec.rb', sample_spec)
      end
    end

    context 'for numbers type' do
      let(:options) { { 'type' => 'numbers', 'operation' => 'add' } }

      it 'creates the metric instrumentation file using the template' do
        described_class.new(args, options).invoke_all

        expect_generated_file(ce_temp_dir, 'count_foo_metric.rb', numbers_sample_metric)
        expect_generated_file(spec_ce_temp_dir, 'count_foo_metric_spec.rb', sample_spec)
      end
    end

    context 'with type option missing' do
      let(:options) { {} }

      it 'raises an ArgumentError' do
        expect { described_class.new(args, options).invoke_all }.to raise_error(ArgumentError, /Type is required/)
      end
    end

    context 'with type option value not included in approved superclasses' do
      let(:options) { { 'type' => 'some_other_type' } }

      it 'raises an ArgumentError' do
        expect { described_class.new(args, options).invoke_all }.to raise_error(ArgumentError, /Unknown type 'some_other_type'/)
      end
    end

    context 'without operation for database metric' do
      let(:options) { { 'type' => 'database' } }

      it 'raises an ArgumentError' do
        expect { described_class.new(args, options).invoke_all }.to raise_error(ArgumentError, /Unknown operation ''/)
      end
    end

    context 'with wrong operation for database metric' do
      let(:options) { { 'type' => 'database', 'operation' => 'sleep' } }

      it 'raises an ArgumentError' do
        expect { described_class.new(args, options).invoke_all }.to raise_error(ArgumentError, /Unknown operation 'sleep'/)
      end
    end

    context 'without operation for numbers metric' do
      let(:options) { { 'type' => 'numbers' } }

      it 'raises an ArgumentError' do
        expect { described_class.new(args, options).invoke_all }.to raise_error(ArgumentError, /Unknown operation ''/)
      end
    end

    context 'with wrong operation for numbers metric' do
      let(:options) { { 'type' => 'numbers', 'operation' => 'sleep' } }

      it 'raises an ArgumentError' do
        expect { described_class.new(args, options).invoke_all }.to raise_error(ArgumentError, /Unknown operation 'sleep'/)
      end
    end
  end
end
