# frozen_string_literal: true

require 'tempfile'
require 'fileutils'
require 'gitlab/rspec/all'
require_relative '../../../../tooling/lib/tooling/predictive_tests'

RSpec.describe Tooling::PredictiveTests, feature_category: :tooling do
  include StubENV

  let(:instance)                       { described_class.new }
  let(:matching_tests_initial_content) { 'initial_matching_spec' }
  let(:fixtures_mapping_content)       { '{}' }

  attr_accessor :changed_files, :changed_files_path, :fixtures_mapping,
    :matching_js_files, :matching_tests, :views_with_partials

  around do |example|
    self.changed_files       = Tempfile.new('test-folder/changed_files.txt')
    self.changed_files_path  = changed_files.path
    self.fixtures_mapping    = Tempfile.new('test-folder/fixtures_mapping.txt')
    self.matching_js_files   = Tempfile.new('test-folder/matching_js_files.txt')
    self.matching_tests      = Tempfile.new('test-folder/matching_tests.txt')
    self.views_with_partials = Tempfile.new('test-folder/views_with_partials.txt')

    # See https://ruby-doc.org/stdlib-1.9.3/libdoc/tempfile/rdoc/
    #     Tempfile.html#class-Tempfile-label-Explicit+close
    begin
      # In practice, we let PredictiveTests create the file, and we just
      # use its file name.
      changed_files.close
      changed_files.unlink

      example.run
    ensure
      # Since example.run can create the file again, let's remove it again
      FileUtils.rm_f(changed_files_path)
      fixtures_mapping.close
      fixtures_mapping.unlink
      matching_js_files.close
      matching_js_files.unlink
      matching_tests.close
      matching_tests.unlink
      views_with_partials.close
      views_with_partials.unlink
    end
  end

  before do
    stub_env(
      'RSPEC_CHANGED_FILES_PATH' => changed_files_path,
      'RSPEC_MATCHING_TESTS_PATH' => matching_tests.path,
      'RSPEC_VIEWS_INCLUDING_PARTIALS_PATH' => views_with_partials.path,
      'FRONTEND_FIXTURES_MAPPING_PATH' => fixtures_mapping.path,
      'RSPEC_MATCHING_JS_FILES_PATH' => matching_js_files.path,
      'RSPEC_TESTS_MAPPING_ENABLED' => "false",
      'RSPEC_TESTS_MAPPING_PATH' => '/tmp/does-not-exist.out'
    )

    # We write some data to later on verify that we only append to this file.
    File.write(matching_tests.path, matching_tests_initial_content)
    File.write(fixtures_mapping.path, fixtures_mapping_content)

    allow(Gitlab).to receive(:configure)
  end

  describe '#execute' do
    subject { instance.execute }

    context 'when ENV variables are missing' do
      before do
        stub_env(
          'RSPEC_CHANGED_FILES_PATH' => '',
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
          expect { subject }.not_to change { File.read(matching_tests.path) }
          expect { subject }.not_to change { File.read(views_with_partials.path) }
          expect { subject }.not_to change { File.read(fixtures_mapping.path) }
          expect { subject }.not_to change { File.read(matching_js_files.path) }
        end
      end

      context 'when some files used for frontend fixtures were changed' do
        let(:changed_files_content) { 'app/models/todo.rb' }
        let(:changed_files_matching_test) { 'spec/models/todo_spec.rb' }
        let(:matching_frontend_fixture) { 'tmp/tests/frontend/fixtures-ee/todos/todos.html' }

        let(:additional_matching_tests) do
          %w[
            spec/models/every_model_spec.rb
            spec/lib/gitlab/import_export/model_configuration_spec.rb
          ].sort.join(' ')
        end

        let(:fixtures_mapping_content) do
          JSON.dump(changed_files_matching_test => [matching_frontend_fixture]) # rubocop:disable Gitlab/Json
        end

        it 'writes to RSPEC_CHANGED_FILES_PATH with API contents and appends with matching fixtures' do
          subject

          expect(File.read(changed_files_path)).to eq("#{changed_files_content} #{matching_frontend_fixture}")
        end

        it 'appends the spec file to RSPEC_MATCHING_TESTS_PATH' do
          expect { subject }.to change { File.read(matching_tests.path) }
            .from(matching_tests_initial_content)
            .to("#{matching_tests_initial_content} #{additional_matching_tests} #{changed_files_matching_test}")
        end

        it 'does not change files other than RSPEC_CHANGED_FILES_PATH nor RSPEC_MATCHING_TESTS_PATH' do
          expect { subject }.not_to change { File.read(views_with_partials.path) }
          expect { subject }.not_to change { File.read(fixtures_mapping.path) }
          expect { subject }.not_to change { File.read(matching_js_files.path) }
        end
      end
    end
  end
end
