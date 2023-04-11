# frozen_string_literal: true

require 'tempfile'
require_relative '../../../../tooling/lib/tooling/predictive_tests'
require_relative '../../../support/helpers/stub_env'

RSpec.describe Tooling::PredictiveTests, feature_category: :tooling do
  include StubENV

  let(:instance)                       { described_class.new }
  let(:matching_tests_initial_content) { 'initial_matching_spec' }

  attr_accessor :changed_files, :fixtures_mapping, :matching_js_files, :matching_tests, :views_with_partials

  around do |example|
    self.changed_files       = Tempfile.new('test-folder/changed_files.txt')
    self.fixtures_mapping    = Tempfile.new('test-folder/fixtures_mapping.txt')
    self.matching_js_files   = Tempfile.new('test-folder/matching_js_files.txt')
    self.matching_tests      = Tempfile.new('test-folder/matching_tests.txt')
    self.views_with_partials = Tempfile.new('test-folder/views_with_partials.txt')

    # See https://ruby-doc.org/stdlib-1.9.3/libdoc/tempfile/rdoc/
    #     Tempfile.html#class-Tempfile-label-Explicit+close
    begin
      example.run
    ensure
      changed_files.close
      changed_files.unlink
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
      'RSPEC_CHANGED_FILES_PATH' => changed_files.path,
      'RSPEC_MATCHING_TESTS_PATH' => matching_tests.path,
      'RSPEC_VIEWS_INCLUDING_PARTIALS_PATH' => views_with_partials.path,
      'FRONTEND_FIXTURES_MAPPING_PATH' => fixtures_mapping.path,
      'RSPEC_MATCHING_JS_FILES_PATH' => matching_js_files.path,
      'RSPEC_TESTS_MAPPING_ENABLED' => "false",
      'RSPEC_TESTS_MAPPING_PATH' => '/tmp/does-not-exist.out'
    )

    # We write some data to later on verify that we only append to this file.
    File.write(matching_tests.path, matching_tests_initial_content)
    File.write(fixtures_mapping.path, '{}') # We write valid JSON, so that the file can be processed
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
        File.write(changed_files, changed_files_content)
      end

      context 'when no files were changed' do
        let(:changed_files_content) { '' }

        it 'does not change any files' do
          expect { subject }.not_to change { File.read(changed_files.path) }
          expect { subject }.not_to change { File.read(matching_tests.path) }
          expect { subject }.not_to change { File.read(views_with_partials.path) }
          expect { subject }.not_to change { File.read(fixtures_mapping.path) }
          expect { subject }.not_to change { File.read(matching_js_files.path) }
        end
      end

      context 'when some files were changed' do
        let(:changed_files_content) { 'tooling/lib/tooling/predictive_tests.rb' }

        it 'appends the spec file to RSPEC_MATCHING_TESTS_PATH' do
          expect { subject }.to change { File.read(matching_tests.path) }
            .from(matching_tests_initial_content)
            .to("#{matching_tests_initial_content} spec/tooling/lib/tooling/predictive_tests_spec.rb")
        end

        it 'does not change files other than RSPEC_MATCHING_TESTS_PATH' do
          expect { subject }.not_to change { File.read(changed_files.path) }
          expect { subject }.not_to change { File.read(views_with_partials.path) }
          expect { subject }.not_to change { File.read(fixtures_mapping.path) }
          expect { subject }.not_to change { File.read(matching_js_files.path) }
        end
      end
    end
  end
end
