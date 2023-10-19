# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../rubocop/cop/experiments_test_coverage'

RSpec.describe RuboCop::Cop::ExperimentsTestCoverage, feature_category: :acquisition do
  let(:class_offense) { described_class::CLASS_OFFENSE }
  let(:block_offense) { described_class::BLOCK_OFFENSE }

  before do
    allow(File).to receive(:exist?).and_return(true)
    allow(File).to receive(:new).and_return(instance_double(File, read: tests_code))
  end

  describe '#on_class' do
    context 'when there are no tests' do
      let(:tests_code) { '' }

      it 'registers an offense' do
        expect_offense(<<~RUBY)
          class ExperimentName < ApplicationExperiment
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{class_offense}
          end
        RUBY
      end
    end

    context 'when there is no stub_experiments' do
      let(:tests_code) { "candidate third" }

      it 'registers an offense' do
        expect_offense(<<~RUBY)
          class ExperimentName < ApplicationExperiment
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{class_offense}
            candidate
            variant(:third) { 'third option' }
          end
        RUBY
      end
    end

    context 'when variant test is missing' do
      let(:tests_code) { "\nstub_experiments(experiment_name: :candidate)" }

      it 'registers an offense' do
        expect_offense(<<~RUBY)
          class ExperimentName < ApplicationExperiment
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{class_offense}
            candidate
            variant(:third) { 'third option' }
          end
        RUBY
      end
    end

    context 'when stub_experiments is commented out' do
      let(:tests_code) do
        "\n# stub_experiments(experiment_name: :candidate, experiment_name: :third)"
      end

      it 'registers an offense' do
        expect_offense(<<~RUBY)
          class ExperimentName < ApplicationExperiment
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{class_offense}
            candidate
            variant(:third) { 'third option' }
          end
        RUBY
      end
    end

    context 'when all tests are present' do
      let(:tests_code) do
        "#\nstub_experiments(experiment_name: :candidate, experiment_name: :third)"
      end

      before do
        allow(cop).to receive(:filepath).and_return('app/experiments/experiment_name_experiment.rb')
      end

      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          class ExperimentName < ApplicationExperiment
            candidate
            variant(:third) { 'third option' }
          end
        RUBY
      end
    end
  end

  describe '#on_block' do
    context 'when there are no tests' do
      let(:tests_code) { '' }

      it 'registers an offense' do
        expect_offense(<<~RUBY)
          experiment(:experiment_name) do |e|
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{block_offense}
          end
        RUBY
      end
    end

    context 'when there is no stub_experiments' do
      let(:tests_code) { "candidate third" }

      it 'registers an offense' do
        expect_offense(<<~RUBY)
          experiment(:experiment_name) do |e|
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{block_offense}
            e.candidate { 'candidate' }
            e.variant(:third) { 'third option' }
            e.run
          end
        RUBY
      end
    end

    context 'when variant test is missing' do
      let(:tests_code) { "\nstub_experiments(experiment_name: :candidate)" }

      it 'registers an offense' do
        expect_offense(<<~RUBY)
          experiment(:experiment_name) do |e|
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{block_offense}
            e.candidate { 'candidate' }
            e.variant(:third) { 'third option' }
            e.run
          end
        RUBY
      end
    end

    context 'when stub_experiments is commented out' do
      let(:tests_code) do
        "\n# stub_experiments(experiment_name: :candidate, experiment_name: :third)"
      end

      it 'registers an offense' do
        expect_offense(<<~RUBY)
          experiment(:experiment_name) do |e|
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{block_offense}
            e.candidate { 'candidate' }
            e.variant(:third) { 'third option' }
            e.run
          end
        RUBY
      end
    end

    context 'when all tests are present' do
      let(:tests_code) do
        "#\nstub_experiments(experiment_name: :candidate, experiment_name: :third)"
      end

      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          experiment(:experiment_name) do |e|
            e.candidate { 'candidate' }
            e.variant(:third) { 'third option' }
            e.run
          end
        RUBY
      end
    end
  end
end
