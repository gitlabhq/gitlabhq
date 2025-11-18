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

      context 'when /lib folder' do
        let(:file_path) { '/lib/tests.rb' }
        let(:test_file_path) { '/spec/lib/tests_spec.rb' }

        it_behaves_like 'covered experiment block'
      end

      context 'when ee/lib folder' do
        let(:file_path) { 'ee/lib/tests.rb' }
        let(:test_file_path) { 'ee/spec/lib/tests_spec.rb' }

        it_behaves_like 'covered experiment block'
      end

      context 'when ee/lib/ee folder' do
        let(:file_path) { 'ee/lib/ee/tests.rb' }
        let(:test_file_path) { 'ee/spec/lib/ee/tests_spec.rb' }

        it_behaves_like 'covered experiment block'
      end

      context 'when *.haml file' do
        let(:file_path) { 'app/view/show_test.html.haml' }
        let(:test_file_path) { 'spec/view/show_test.html.haml_spec.rb' }

        it_behaves_like 'covered experiment block'
      end

      context 'when experiment is in a Base class' do
        let(:file_path) { 'app/services/base_class_example.rb' }
        let(:test_file_path) { 'spec/services/base_class_example_spec.rb' }
        let(:dir) { File.dirname(test_file_path) }
        let(:tests_code) { '' }
        let(:child) { 'standard_namespace_create_service_spec.rb' }
        let(:child_path) { File.join(dir, child) }

        before do
          allow(Dir).to receive(:exist?).with(dir).and_return(true)
          allow(Dir).to receive(:children).with(dir).and_return([child])

          stub_file_read(child_path,
            content: "stub_experiments(premium_trial_positioning: :candidate)"
          )
        end

        it 'does not register an offense, if the child class has tests' do
          expect_no_offenses(<<~RUBY)
            class BaseClassExample
              experiment(:premium_trial_positioning, actor: user) do |e|
                e.candidate { 'candidate' }
              end
            end
          RUBY
        end

        it 'registers an offense, if the child class does not have tests' do
          stub_file_read(child_path,
            content: ""
          )

          expect_offense(<<~RUBY)
            class BaseClassExample
              experiment(:premium_trial_positioning, actor: user) do |e|
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{block_offense}
                e.candidate { 'candidate' }
              end
            end
          RUBY
        end

        it 'registers an offense, if test directory does not exist' do
          allow(Dir).to receive(:exist?).with(dir).and_return(false)

          expect_offense(<<~RUBY)
            class BaseClassExample
              experiment(:premium_trial_positioning, actor: user) do |e|
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{block_offense}
                e.candidate { 'candidate' }
              end
            end
          RUBY
        end

        it 'does not register an offense, if there is a non spec file in the directory' do
          allow(Dir).to receive(:children).with(dir).and_return([child, 'README.md'])

          expect_no_offenses(<<~RUBY)
            class BaseClassExample
              experiment(:premium_trial_positioning, actor: user) do |e|
                e.candidate { 'candidate' }
              end
            end
          RUBY
        end
      end

      context 'when using shared examples' do
        let(:file_path) { 'app/controllers/test_controller.rb' }
        let(:test_file_path) { 'spec/requests/test_controller_spec.rb' }
        let(:shared_examples_path) { 'spec/support/shared_examples/experiments/coverage_spec_helpers.rb' }

        let(:tests_code) do
          <<~RUBY
            include_examples 'experiment coverage'
          RUBY
        end

        before do
          allow(Dir).to receive(:glob)
            .with('spec/support/shared_examples/**/*.rb')
            .and_return([shared_examples_path])
          allow(Dir).to receive(:glob)
            .with('ee/spec/support/shared_examples/**/*.rb')
            .and_return([])

          stub_file_read(
            shared_examples_path,
            content: <<~RUBY
              shared_examples 'experiment coverage' do
                stub_experiments(experiment_name: :candidate, experiment_name: :third)
              end
            RUBY
          )
        end

        it 'does not register an offense, if shared examples test variants' do
          expect_no_offenses(<<~RUBY)
            experiment(:experiment_name) do |e|
              e.candidate { 'candidate' }
              e.variant(:third) { 'third option' }
              e.run
            end
          RUBY
        end

        it 'registers an offense, if shared examples do not test variants' do
          stub_file_read(
            shared_examples_path,
            content: <<~RUBY
              shared_examples 'experiment coverage' do
                # test code
              end
            RUBY
          )

          expect_offense(<<~RUBY)
            experiment(:experiment_name) do |e|
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{block_offense}
              e.candidate { 'candidate' }
              e.variant(:third) { 'third option' }
              e.run
            end
          RUBY
        end

        it 'registers an offense, if there are no matching shared examples' do
          stub_file_read(
            shared_examples_path,
            content: <<~RUBY
              shared_examples 'something else' do
                # test code
              end
            RUBY
          )

          expect_offense(<<~RUBY)
            experiment(:experiment_name) do |e|
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{block_offense}
              e.candidate { 'candidate' }
              e.variant(:third) { 'third option' }
              e.run
            end
          RUBY
        end

        context 'if no shared example methods are used' do
          let(:tests_code) { '' }

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
      end
    end
  end
end
