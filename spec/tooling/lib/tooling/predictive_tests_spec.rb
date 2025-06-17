# frozen_string_literal: true

# rubocop:disable Gitlab/Json -- no Rails environment

require 'tempfile'
require 'fileutils'
require 'fast_spec_helper'
require_relative '../../../../tooling/lib/tooling/predictive_tests'

RSpec.describe Tooling::PredictiveTests, feature_category: :tooling do
  include StubENV

  let(:instance) { described_class.new }
  let(:matching_test_files_initial_content) { 'initial_matching_spec.rb' }
  let(:fixtures_mapping_content) { '{}' }
  let(:event_tracker) { instance_double(Tooling::Events::TrackPipelineEvents, send_event: nil) }

  let(:test_strategy) { "described_class" }
  let(:todo_spec) { 'spec/models/todo_spec.rb' }
  let(:user_spec) { 'spec/models/user_spec.rb' }
  let(:project_spec) { 'spec/models/project_spec.rb' }
  let(:other_spec) { 'spec/models/other_spec.rb' }
  let(:user_model) { 'app/models/user.rb' }
  let(:todo_model) { 'app/models/todo.rb' }
  let(:project_model) { 'app/models/project.rb' }
  let(:other_model) { 'app/models/other.rb' }
  let(:user_controller_spec) { 'spec/controllers/users_controller_spec.rb' }
  let(:integration_spec) { 'spec/integration/user_spec.rb' }
  let(:admin_controller_spec) { 'spec/controllers/admin_controller_spec.rb' }

  # Create a unique temporary directory for each test run
  # This ensures that tests do not interfere with each other's state.
  let(:temp_dir) { Dir.mktmpdir('predictive-tests-') }
  let(:failed_test_files_dir) { File.join(temp_dir, 'failed_test_files') }

  let(:base_env_vars) do
    {
      'RSPEC_CHANGED_FILES_PATH' => changed_files_path,
      'RSPEC_MATCHING_TEST_FILES_PATH' => matching_test_files.path,
      'RSPEC_VIEWS_INCLUDING_PARTIALS_PATH' => views_with_partials.path,
      'FRONTEND_FIXTURES_MAPPING_PATH' => fixtures_mapping.path,
      'RSPEC_MATCHING_JS_FILES_PATH' => matching_js_files.path,
      'RSPEC_TESTS_MAPPING_ENABLED' => "false",
      'RSPEC_TESTS_MAPPING_PATH' => crystalball_mapping_file.path,
      'GLCI_RSPEC_FAILED_TESTS_DIR' => failed_test_files_dir,
      'GLCI_PREDICTIVE_TESTS_METRICS_PATH' => metrics_output_file.path,
      'GLCI_PREDICTIVE_TESTS_GENERATE_METRICS' => 'false',
      'GLCI_PREDICTIVE_TESTS_TRACK_EVENTS' => 'false',
      'CI_JOB_ID' => '123'
    }
  end

  attr_accessor :changed_files, :changed_files_path, :fixtures_mapping,
    :matching_js_files, :matching_test_files, :views_with_partials,
    :crystalball_mapping_file, :metrics_output_file

  around do |example|
    # Create the failed tests directory
    FileUtils.mkdir_p(failed_test_files_dir)

    self.changed_files       = Tempfile.new('test-folder/changed_files.txt')
    self.changed_files_path  = changed_files.path
    self.fixtures_mapping    = Tempfile.new('test-folder/fixtures_mapping.txt')
    self.matching_js_files   = Tempfile.new('test-folder/matching_js_files.txt')
    self.matching_test_files = Tempfile.new('test-folder/matching_test_files.txt')
    self.views_with_partials = Tempfile.new('test-folder/views_with_partials.txt')
    self.crystalball_mapping_file = Tempfile.new('test-folder/crystalball_mapping.json')
    self.metrics_output_file = Tempfile.new('test-folder/metrics.json')

    # See https://ruby-doc.org/stdlib-1.9.3/libdoc/tempfile/rdoc/
    #     Tempfile.html#class-Tempfile-label-Explicit+close
    begin
      # In practice, we let PredictiveTests create the file, and we just
      # use its file name.
      changed_files.close
      changed_files.unlink

      example.run
    ensure
      # Clean up the temporary directory and all its contents
      FileUtils.rm_rf(temp_dir)

      # Since example.run can create the file again, let's remove it again
      FileUtils.rm_f(changed_files_path)
      [fixtures_mapping, matching_js_files, matching_test_files, views_with_partials, crystalball_mapping_file,
        metrics_output_file].each do |file|
        file.close
        file.unlink
      end
    end
  end

  before do
    stub_env(base_env_vars)

    # We write some data to later on verify that we only append to this file.
    File.write(matching_test_files.path, matching_test_files_initial_content)
    File.write(fixtures_mapping.path, fixtures_mapping_content)

    allow(Gitlab).to receive(:configure)
    allow(Tooling::Events::TrackPipelineEvents).to receive(:new).and_return(event_tracker)
  end

  describe '#execute' do
    subject { instance.execute }

    context 'when ENV variables are missing' do
      before do
        stub_env(
          'RSPEC_CHANGED_FILES_PATH' => nil,
          'FRONTEND_FIXTURES_MAPPING_PATH' => ''
        )
      end

      it 'raises an error' do
        expect { subject }.to raise_error(
          '[predictive tests] Missing ENV variable(s): RSPEC_CHANGED_FILES_PATH,FRONTEND_FIXTURES_MAPPING_PATH.'
        )
      end
    end

    context 'when all ENV variables are provided' do
      before do
        change = double('GitLab::Change') # rubocop:disable RSpec/VerifiedDoubles
        allow(change).to receive_message_chain(:to_h, :values_at)
          .and_return([changed_files_content, changed_files_content])

        allow(Gitlab).to receive_message_chain(:merge_request_changes, :changes)
          .and_return([change])
      end

      context 'when no files were changed' do
        let(:changed_files_content) { '' }

        it 'does not change files other than RSPEC_CHANGED_FILES_PATH' do
          expect { subject }.not_to change { File.read(matching_test_files.path) }
          expect { subject }.not_to change { File.read(views_with_partials.path) }
          expect { subject }.not_to change { File.read(fixtures_mapping.path) }
          expect { subject }.not_to change { File.read(matching_js_files.path) }
        end
      end

      context 'when some files used for frontend fixtures were changed' do
        let(:changed_files_content) { todo_model }
        let(:changed_files_matching_test) { todo_spec }
        let(:matching_frontend_fixture) { 'tmp/tests/frontend/fixtures-ee/todos/todos.html' }

        let(:additional_matching_tests) do
          %w[
            spec/models/every_model_spec.rb
            spec/lib/gitlab/import_export/model_configuration_spec.rb
          ].sort.join(' ')
        end

        let(:fixtures_mapping_content) do
          JSON.dump(changed_files_matching_test => [matching_frontend_fixture])
        end

        it 'writes to RSPEC_CHANGED_FILES_PATH with API contents and appends with matching fixtures' do
          subject

          expect(File.read(changed_files_path)).to eq("#{changed_files_content} #{matching_frontend_fixture}")
        end

        it 'appends the spec file to RSPEC_MATCHING_TEST_FILES_PATH' do
          expect { subject }.to change { File.read(matching_test_files.path) }
            .from(matching_test_files_initial_content)
            .to("#{matching_test_files_initial_content} #{additional_matching_tests} #{changed_files_matching_test}")
        end

        it 'does not change files other than RSPEC_CHANGED_FILES_PATH nor RSPEC_MATCHING_TEST_FILES_PATH' do
          expect { subject }.not_to change { File.read(views_with_partials.path) }
          expect { subject }.not_to change { File.read(fixtures_mapping.path) }
          expect { subject }.not_to change { File.read(matching_js_files.path) }
        end
      end

      context 'when metrics generation is enabled with various mapping scenarios' do
        let(:changed_files_content) { "#{user_model}\n#{todo_model}\n#{project_model}" }
        let(:crystalball_mapping_content) { {} }

        before do
          change = double('GitLab::Change') # rubocop:disable RSpec/VerifiedDoubles -- reuse existing mock
          allow(change).to receive_message_chain(:to_h, :values_at)
            .and_return([changed_files_content, changed_files_content])

          allow(Gitlab).to receive_message_chain(:merge_request_changes, :changes)
            .and_return([change])

          stub_env('GLCI_PREDICTIVE_TESTS_GENERATE_METRICS' => 'true')
          File.write(crystalball_mapping_file.path, crystalball_mapping_content)
        end

        it 'creates metrics output file' do
          subject
          expect(File.exist?(metrics_output_file.path)).to be true
        end

        it 'handles missing failed tests file gracefully' do
          FileUtils.rm_f(File.join(failed_test_files_dir, Tooling::PredictiveTests::RSPEC_ALL_FAILED_TESTS_FILE))

          expect { subject }.not_to raise_error
          expect(File.exist?(metrics_output_file.path)).to be true
        end

        it 'continues execution when metrics generation fails' do
          allow(File).to receive(:read).and_call_original
          allow(File).to receive(:read).with(/rspec_all_failed_tests\.txt/).and_raise(StandardError.new("Test error"))

          expect { subject }.not_to raise_error
        end

        it 'saves metrics to specified path' do
          custom_path = File.join(File.dirname(metrics_output_file.path), 'custom_metrics.json')
          stub_env('GLCI_PREDICTIVE_TESTS_METRICS_PATH' => custom_path)

          subject

          expect(File.exist?(custom_path)).to be true
        end

        context 'when all changed files are in crystalball mapping' do
          let(:crystalball_mapping_content) do
            JSON.dump({
              user_model => [user_spec],
              todo_model => [todo_spec],
              project_model => [project_spec]
            })
          end

          it 'finds all changed files in mapping' do
            subject

            metrics_data = read_metrics
            expect(metrics_data['core_metrics']['changed_files_in_mapping']).to eq(3)
          end
        end

        context 'when no changed files are in crystalball mapping' do
          let(:crystalball_mapping_content) do
            JSON.dump({
              other_model => [other_spec]
            })
          end

          it 'finds no changed files in mapping' do
            subject

            metrics_data = read_metrics
            expect(metrics_data['core_metrics']['changed_files_in_mapping']).to eq(0)
          end
        end

        context 'when some changed files are in crystalball mapping' do
          let(:crystalball_mapping_content) do
            JSON.dump({
              user_model => [user_spec],
              other_model => [other_spec]
            })
          end

          it 'finds changed files in mapping' do
            subject

            metrics_data = read_metrics
            expect(metrics_data['core_metrics']['changed_files_in_mapping']).to eq(1)
          end
        end

        context 'when crystalball mapping file is missing' do
          before do
            FileUtils.rm_f(crystalball_mapping_file.path)
          end

          it 'handles missing mapping gracefully' do
            expect { subject }.not_to raise_error

            metrics_data = read_metrics
            expect(metrics_data['mapping_metrics']['total_test_files_in_mapping']).to eq(0)
          end
        end

        context 'when crystalball mapping file is corrupted' do
          before do
            File.write(crystalball_mapping_file.path, 'invalid json content')
          end

          it 'handles corrupted mapping gracefully' do
            expect { subject }.not_to raise_error

            metrics_data = read_metrics
            expect(metrics_data['mapping_metrics']['total_test_files_in_mapping']).to eq(0)
          end
        end

        context 'when failed tests overlap with predicted tests' do
          let(:failed_tests_content) { "#{user_spec} #{project_spec}" }
          let(:crystalball_mapping_content) do
            JSON.dump({
              user_model => [user_spec],
              todo_model => [todo_spec]
            })
          end

          before do
            write_failed_tests_file(failed_tests_content)
          end

          it 'calculates metrics correctly' do
            subject

            metrics_data = read_metrics
            core_metrics = metrics_data['core_metrics']
            mapping_metrics = metrics_data['mapping_metrics']

            expect(core_metrics['changed_files_count']).to eq(3)
            # predicted tests is the superset of crystalball mapping and other
            # pattern mappings. Here, it includes matching_test_files_initial_content and
            # additional_matching_tests (tests.yml mapping) since we append to the file
            expect(core_metrics['predicted_test_files_count']).to eq(6)
            expect(core_metrics['missed_failing_test_files']).to eq(0)
            expect(core_metrics['failed_test_files_count']).to eq(2)
            expect(core_metrics['changed_files_in_mapping']).to eq(2)
            expect(mapping_metrics['total_test_files_in_mapping']).to eq(2)
            expect(mapping_metrics['test_files_selected_by_crystalball']).to eq(2)
            expect(mapping_metrics['failed_test_files_in_mapping']).to eq(1)
          end
        end

        context 'when prediction misses some failed tests' do
          let(:changed_files_content) { todo_model }
          let(:failed_tests_content) { "#{todo_spec} #{user_spec} #{admin_controller_spec}" }
          let(:crystalball_mapping_content) do
            JSON.dump({
              todo_model => [todo_spec],
              other_model => [other_spec]
            })
          end

          before do
            write_failed_tests_file(failed_tests_content)
          end

          it 'correctly identifies missed failing tests' do
            subject

            metrics_data = read_metrics
            core_metrics = metrics_data['core_metrics']
            mapping_metrics = metrics_data['mapping_metrics']

            expect(core_metrics['predicted_test_files_count']).to eq(4)
            expect(core_metrics['failed_test_files_count']).to eq(3)
            expect(core_metrics['changed_files_count']).to eq(1)
            expect(core_metrics['missed_failing_test_files']).to eq(2)
            expect(mapping_metrics['total_test_files_in_mapping']).to eq(2)
            expect(mapping_metrics['test_files_selected_by_crystalball']).to eq(1)
            expect(mapping_metrics['failed_test_files_in_mapping']).to eq(1)
          end
        end

        context 'when PREDICTIVE_TEST_TRACK_EVENTS env variable is true' do
          before do
            stub_env('GLCI_PREDICTIVE_TESTS_TRACK_EVENTS' => 'true')
          end

          it 'tracks metrics events' do
            subject

            metrics_data = read_metrics
            core_metrics = metrics_data['core_metrics']

            expect(event_tracker).to have_received(:send_event).with(
              "glci_predictive_tests_metrics",
              label: "changed_files_count",
              value: core_metrics['changed_files_count'],
              property: "described_class",
              extra_properties: { ci_job_id: '123' }
            )

            expect(event_tracker).to have_received(:send_event).with(
              "glci_predictive_tests_metrics",
              label: "predicted_test_files_count",
              value: core_metrics['predicted_test_files_count'],
              property: "described_class",
              extra_properties: { ci_job_id: '123' }
            )

            expect(event_tracker).to have_received(:send_event).with(
              "glci_predictive_tests_metrics",
              label: "missed_failing_test_files",
              value: core_metrics['missed_failing_test_files'],
              property: "described_class",
              extra_properties: { ci_job_id: '123' }
            )
          end
        end
      end
    end
  end

  describe 'helper methods' do
    let(:instance) do
      stub_const('ENV', {
        'RSPEC_CHANGED_FILES_PATH' => '/tmp/changed_files.txt',
        'RSPEC_MATCHING_TEST_FILES_PATH' => '/tmp/matching_test_files.txt',
        'RSPEC_VIEWS_INCLUDING_PARTIALS_PATH' => '/tmp/views.txt',
        'FRONTEND_FIXTURES_MAPPING_PATH' => '/tmp/fixtures.txt',
        'RSPEC_MATCHING_JS_FILES_PATH' => '/tmp/js_files.txt'
      })
      described_class.new
    end

    describe '#crystalball_mapping' do
      let(:mapping_file) { Tempfile.new('mapping.json') }

      after do
        mapping_file.close
        mapping_file.unlink
      end

      context 'when mapping file contains valid JSON' do
        let(:mapping_content) do
          JSON.dump({
            user_model => [user_spec],
            'app/controllers/users_controller.rb' => [user_controller_spec]
          })
        end

        before do
          File.write(mapping_file.path, mapping_content)
          allow(instance).to receive(:crystalball_mapping_path).and_return(mapping_file.path)
        end

        it 'loads and parses the JSON correctly' do
          result = instance.send(:crystalball_mapping)

          expect(result).to be_a(Hash)
          expect(result[user_model]).to eq([user_spec])
          expect(result['app/controllers/users_controller.rb']).to eq([user_controller_spec])
        end
      end

      context 'when mapping file contains invalid JSON' do
        before do
          File.write(mapping_file.path, 'invalid json content')
          allow(instance).to receive(:crystalball_mapping_path).and_return(mapping_file.path)
        end

        it 'returns empty hash for invalid JSON' do
          result = instance.send(:crystalball_mapping)
          expect(result).to eq({})
        end
      end

      context 'when mapping file does not exist' do
        before do
          allow(instance).to receive(:crystalball_mapping_path).and_return('/nonexistent/path.json')
        end

        it 'returns empty hash for missing file' do
          result = instance.send(:crystalball_mapping)
          expect(result).to eq({})
        end
      end
    end
  end

  def write_failed_tests_file(content)
    failed_tests_path = File.join(failed_test_files_dir, Tooling::PredictiveTests::RSPEC_ALL_FAILED_TESTS_FILE)
    File.write(failed_tests_path, content)
  end

  def read_metrics
    JSON.parse(File.read(metrics_output_file.path))
  end
end
# rubocop:enable Gitlab/Json
