# frozen_string_literal: true

# rubocop:disable Gitlab/Json -- no Rails environment

require 'tempfile'
require 'fileutils'
require 'fast_spec_helper'

require_relative '../../../../../tooling/lib/tooling/predictive_tests/test_selector'

RSpec.describe Tooling::PredictiveTests::TestSelector, feature_category: :tooling do
  include StubENV

  subject(:test_selector) do
    described_class.new(
      rspec_changed_files_path: changed_files_path,
      rspec_matching_test_files_path: matching_test_files.path,
      rspec_views_including_partials_path: views_with_partials.path,
      frontend_fixtures_mapping_path: fixtures_mapping.path,
      rspec_matching_js_files_path: matching_js_files.path
    )
  end

  let(:matching_test_files_initial_content) { 'initial_matching_spec.rb' }
  let(:fixtures_mapping_content) { '{}' }

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

  attr_accessor :changed_files,
    :changed_files_path,
    :fixtures_mapping,
    :matching_js_files,
    :matching_test_files,
    :views_with_partials

  around do |example|
    self.changed_files = Tempfile.new('test-folder/changed_files.txt')
    self.changed_files_path = changed_files.path
    self.fixtures_mapping = Tempfile.new('test-folder/fixtures_mapping.txt')
    self.matching_js_files = Tempfile.new('test-folder/matching_js_files.txt')
    self.matching_test_files = Tempfile.new('test-folder/matching_test_files.txt')
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
      [fixtures_mapping, matching_js_files, matching_test_files, views_with_partials].each do |file|
        file.close
        file.unlink
      end
    end
  end

  before do
    stub_env({ 'RSPEC_TESTS_MAPPING_ENABLED' => "false" })

    # We write some data to later on verify that we only append to this file.
    File.write(matching_test_files.path, matching_test_files_initial_content)
    File.write(fixtures_mapping.path, fixtures_mapping_content)

    allow(Gitlab).to receive(:configure)
  end

  describe '#execute' do
    before do
      change = double('GitLab::Change') # rubocop:disable RSpec/VerifiedDoubles -- avoid having to load gitlab gem
      allow(change).to receive_message_chain(:to_h, :values_at)
        .and_return([changed_files_content, changed_files_content])

      allow(Gitlab).to receive_message_chain(:merge_request_changes, :changes)
        .and_return([change])
    end

    context 'when no files were changed' do
      let(:changed_files_content) { '' }

      it 'does not change files other than RSPEC_CHANGED_FILES_PATH' do
        expect { test_selector.execute }.not_to change { File.read(matching_test_files.path) }
        expect { test_selector.execute }.not_to change { File.read(views_with_partials.path) }
        expect { test_selector.execute }.not_to change { File.read(fixtures_mapping.path) }
        expect { test_selector.execute }.not_to change { File.read(matching_js_files.path) }
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
        test_selector.execute

        expect(File.read(changed_files_path)).to eq("#{changed_files_content} #{matching_frontend_fixture}")
      end

      it 'appends the spec file to RSPEC_MATCHING_TEST_FILES_PATH' do
        expect { test_selector.execute }.to change { File.read(matching_test_files.path) }
          .from(matching_test_files_initial_content)
          .to("#{matching_test_files_initial_content} #{additional_matching_tests} #{changed_files_matching_test}")
      end

      it 'does not change files other than RSPEC_CHANGED_FILES_PATH nor RSPEC_MATCHING_TEST_FILES_PATH' do
        expect { test_selector.execute }.not_to change { File.read(views_with_partials.path) }
        expect { test_selector.execute }.not_to change { File.read(fixtures_mapping.path) }
        expect { test_selector.execute }.not_to change { File.read(matching_js_files.path) }
      end
    end
  end
end
# rubocop:enable Gitlab/Json
