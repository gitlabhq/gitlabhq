# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../rubocop/cop/experiments_test_coverage'
require_relative '../../support/helpers/file_read_helpers'

RSpec.describe RuboCop::Cop::ExperimentsTestCoverage, feature_category: :acquisition do
  include FileReadHelpers

  let(:class_offense) { described_class::CLASS_OFFENSE }
  let(:block_offense) { described_class::BLOCK_OFFENSE }

  before do
    allow_next_instance_of(Parser::Source::Buffer) do |node_buffer|
      allow(node_buffer).to receive(:name).and_return(file_path)
    end

    stub_file_read(test_file_path, content: tests_code)
  end

  describe '#on_class' do
    let(:file_path) { 'app/experiments/experiment_name_experiment.rb' }
    let(:test_file_path) { 'spec/experiments/experiment_name_experiment_spec.rb' }

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
    let(:file_path) { 'app/controllers/test_controller.rb' }
    let(:test_file_path) { 'spec/requests/test_controller_spec.rb' }

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
      shared_examples 'covered experiment block' do
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

      let(:tests_code) do
        "#\nstub_experiments(experiment_name: :candidate, experiment_name: :third)"
      end

      it_behaves_like 'covered experiment block'

      context 'when /lib/api folder' do
        let(:file_path) { '/lib/api/tests.rb' }
        let(:test_file_path) { '/spec/requests/api/tests_spec.rb' }

        it_behaves_like 'covered experiment block'
      end

      context 'when *.haml file' do
        let(:file_path) { 'app/view/show_test.html.haml' }
        let(:test_file_path) { 'spec/view/show_test.html.haml_spec.rb' }

        it_behaves_like 'covered experiment block'
      end
    end
  end
end
