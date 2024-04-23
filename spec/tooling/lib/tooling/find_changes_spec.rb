# frozen_string_literal: true

require_relative '../../../../tooling/lib/tooling/find_changes'
require 'gitlab/rspec/all'
require 'json'
require 'tempfile'

RSpec.describe Tooling::FindChanges, feature_category: :tooling do
  include StubENV

  attr_accessor :changed_files_file, :predictive_tests_file, :frontend_fixtures_mapping_file

  let(:instance) do
    described_class.new(
      changed_files_pathname: changed_files_pathname,
      predictive_tests_pathname: predictive_tests_pathname,
      frontend_fixtures_mapping_pathname: frontend_fixtures_mapping_pathname,
      from: from,
      file_filter: file_filter,
      only_new_paths: only_new_paths)
  end

  let(:changed_files_pathname)             { changed_files_file.path }
  let(:predictive_tests_pathname)          { predictive_tests_file.path }
  let(:frontend_fixtures_mapping_pathname) { frontend_fixtures_mapping_file.path }
  let(:from)                               { :api }
  let(:gitlab_client)                      { double('GitLab') } # rubocop:disable RSpec/VerifiedDoubles
  let(:file_filter)                        { ->(_) { true } }
  let(:only_new_paths)                     { false }
  let(:project_token)                      { 'dummy-token' }
  let(:find_changes_api_token)             { nil }
  let(:find_changes_mr_project_path)       { nil }
  let(:find_changes_mr_iid)                { nil }

  around do |example|
    self.changed_files_file             = Tempfile.new('changed_files_file')
    self.predictive_tests_file          = Tempfile.new('predictive_tests_file')
    self.frontend_fixtures_mapping_file = Tempfile.new('frontend_fixtures_mapping_file')

    # See https://ruby-doc.org/stdlib-1.9.3/libdoc/tempfile/rdoc/
    #     Tempfile.html#class-Tempfile-label-Explicit+close
    begin
      example.run
    ensure
      frontend_fixtures_mapping_file.close
      frontend_fixtures_mapping_file.unlink
      predictive_tests_file.close
      predictive_tests_file.unlink
      changed_files_file.close
      changed_files_file.unlink
    end
  end

  before do
    stub_env(
      'CI_API_V4_URL' => 'gitlab_api_url',
      'CI_MERGE_REQUEST_IID' => '1234',
      'CI_MERGE_REQUEST_PROJECT_PATH' => 'dummy-project',
      'PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE' => project_token,
      'FIND_CHANGES_API_TOKEN' => find_changes_api_token,
      'FIND_CHANGES_MERGE_REQUEST_PROJECT_PATH' => find_changes_mr_project_path,
      'FIND_CHANGES_MERGE_REQUEST_IID' => find_changes_mr_iid
    )
  end

  describe '#initialize' do
    context 'when fetching changes from unknown' do
      let(:from) { :unknown }

      it 'raises an ArgumentError' do
        expect { instance }.to raise_error(
          ArgumentError, ":from can only be :api or :changed_files"
        )
      end
    end

    describe '#gitlab_token' do
      it 'sets to PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE' do
        expect(instance.__send__(:gitlab_token)).to eq('dummy-token')
      end

      context 'when FIND_CHANGES_API_TOKEN is set' do
        let(:find_changes_api_token) { 'mummy-token' }

        it 'sets to PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE' do
          expect(instance.__send__(:gitlab_token)).to eq('dummy-token')
        end

        context 'when FIND_CHANGES_MERGE_REQUEST_PROJECT_PATH is set' do
          let(:find_changes_mr_project_path) { 'mummy-project' }

          it 'sets to PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE' do
            expect(instance.__send__(:gitlab_token)).to eq('mummy-token')
          end
        end
      end

      context 'when PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE is not set' do
        let(:project_token) { nil }

        it 'sets to an empty string' do
          expect(instance.__send__(:gitlab_token)).to eq('')
        end
      end
    end

    describe '#mr_project_path' do
      it 'sets to CI_MERGE_REQUEST_PROJECT_PATH' do
        expect(instance.__send__(:mr_project_path)).to eq('dummy-project')
      end

      context 'when FIND_CHANGES_MERGE_REQUEST_PROJECT_PATH is set' do
        let(:find_changes_mr_project_path) { 'mummy-project' }

        it 'sets to FIND_CHANGES_MERGE_REQUEST_PROJECT_PATH' do
          expect(instance.__send__(:mr_project_path)).to eq('mummy-project')
        end
      end
    end

    describe '#mr_iid' do
      it 'sets to CI_MERGE_REQUEST_PROJECT_PATH' do
        expect(instance.__send__(:mr_iid)).to eq('1234')
      end

      context 'when FIND_CHANGES_MERGE_REQUEST_PROJECT_PATH is set' do
        let(:find_changes_mr_iid) { '1357' }

        it 'sets to FIND_CHANGES_MERGE_REQUEST_PROJECT_PATH' do
          expect(instance.__send__(:mr_iid)).to eq('1357')
        end
      end
    end
  end

  describe '#execute' do
    subject { instance.execute }

    before do
      allow(instance).to receive(:gitlab).and_return(gitlab_client)
    end

    context 'when there is no changed files file' do
      let(:changed_files_pathname) { nil }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(
          ArgumentError, "A path to the changed files file must be given as :changed_files_pathname"
        )
      end
    end

    context 'when fetching changes from API' do
      let(:from) { :api }

      it 'calls GitLab API to retrieve the MR diff' do
        expect(gitlab_client).to receive_message_chain(:merge_request_changes, :changes).and_return([])

        subject
      end

      context 'when used with file_filter' do
        let(:file_filter) { ->(file) { file['new_path'] =~ %r{doc/.*} } }

        let(:mr_changes_array) do
          [
            {
              "new_path" => "scripts/test.js",
              "old_path" => "scripts/test.js"
            },
            {
              "new_path" => "doc/index.md",
              "old_path" => "doc/index.md"
            }
          ]
        end

        before do
          # rubocop:disable RSpec/VerifiedDoubles -- The class from the GitLab gem isn't public, so we cannot use verified doubles for it.
          allow(gitlab_client).to receive(:merge_request_changes)
            .with('dummy-project', '1234')
            .and_return(double(changes: mr_changes_array))
          # rubocop:enable RSpec/VerifiedDoubles
        end

        it 'only writes matching files to output' do
          subject

          expect(File.read(changed_files_file)).to eq('doc/index.md')
        end
      end

      context 'when used with only_new_paths' do
        let(:only_new_paths) { true }

        let(:mr_changes_array) do
          [
            {
              "new_path" => "scripts/test.js",
              "old_path" => "scripts/test.js"
            },
            {
              "new_path" => "doc/renamed_index.md",
              "old_path" => "doc/index.md"
            }
          ]
        end

        before do
          # rubocop:disable RSpec/VerifiedDoubles -- The class from the GitLab gem isn't public, so we cannot use verified doubles for it.
          allow(gitlab_client).to receive(:merge_request_changes)
            .with('dummy-project', '1234')
            .and_return(double(changes: mr_changes_array))
          # rubocop:enable RSpec/VerifiedDoubles
        end

        it 'only writes new file paths to output' do
          subject

          expect(File.read(changed_files_file)).to eq('doc/renamed_index.md scripts/test.js')
        end
      end
    end

    context 'when fetching changes from changed files' do
      let(:from) { :changed_files }

      it 'does not call GitLab API to retrieve the MR diff' do
        expect(gitlab_client).not_to receive(:merge_request_changes)

        subject
      end

      context 'when there are no file changes' do
        it 'writes an empty string to changed files file' do
          expect { subject }.not_to change { File.read(changed_files_pathname) }
        end
      end

      context 'when there are file changes' do
        before do
          File.write(changed_files_pathname, changed_files_file_content)
        end

        let(:changed_files_file_content) { 'first_file_changed second_file_changed' }

        # This is because we don't have frontend fixture mappings: we will just write the same data that we read.
        it 'does not change the changed files file' do
          expect { subject }.not_to change { File.read(changed_files_pathname) }
        end
      end

      context 'when there is no matched tests file' do
        let(:predictive_tests_pathname) { nil }

        it 'does not add frontend fixtures mapping to the changed files file' do
          expect { subject }.not_to change { File.read(changed_files_pathname) }
        end
      end

      context 'when there is no frontend fixture files' do
        let(:frontend_fixtures_mapping_pathname) { nil }

        it 'does not add frontend fixtures mapping to the changed files file' do
          expect { subject }.not_to change { File.read(changed_files_pathname) }
        end
      end

      context 'when the matched tests file and frontend fixture files are provided' do
        before do
          File.write(predictive_tests_pathname, matched_tests)
          File.write(frontend_fixtures_mapping_pathname, frontend_fixtures_mapping_json)
          File.write(changed_files_pathname, changed_files_file_content)
        end

        let(:changed_files_file_content) { '' }

        context 'when there are no mappings for the matched tests' do
          let(:matched_tests) { 'match_spec1 match_spec_2' }
          let(:frontend_fixtures_mapping_json) do
            { other_spec: ['other_mapping'] }.to_json
          end

          it 'does not change the changed files file' do
            expect { subject }.not_to change { File.read(changed_files_pathname) }
          end
        end

        context 'when there are available mappings for the matched tests' do
          let(:matched_tests) { 'match_spec1 match_spec_2' }
          let(:spec_mappings) { %w[spec1_mapping1 spec1_mapping2] }
          let(:frontend_fixtures_mapping_json) do
            { match_spec1: spec_mappings }.to_json
          end

          context 'when the changed files file is initially empty' do
            it 'adds the frontend fixtures mappings to the changed files file' do
              expect { subject }.to change { File.read(changed_files_pathname) }.from('').to(spec_mappings.join(' '))
            end
          end

          context 'when the changed files file is initially not empty' do
            let(:changed_files_file_content) { 'initial_content1 initial_content2' }

            it 'adds the frontend fixtures mappings to the changed files file' do
              expect { subject }.to change { File.read(changed_files_pathname) }
                .from(changed_files_file_content)
                .to("#{changed_files_file_content} #{spec_mappings.join(' ')}")
            end
          end
        end
      end
    end
  end

  describe '#only_allowed_files_changed' do
    subject { instance.only_allowed_files_changed }

    context 'when fetching changes from changed files' do
      let(:from) { :changed_files }

      before do
        File.write(changed_files_pathname, changed_files_file_content)
      end

      context 'when changed files contain only *.js changes' do
        let(:changed_files_file_content) { 'a.js b.js' }

        it 'returns true' do
          expect(subject).to be true
        end
      end

      context 'when changed files contain both *.vue and *.js changes' do
        let(:changed_files_file_content) { 'a.js b.vue' }

        it 'returns true' do
          expect(subject).to be true
        end
      end

      context 'when changed files contain not allowed changes' do
        let(:changed_files_file_content) { 'a.js b.vue c.rb' }

        it 'returns false' do
          expect(subject).to be false
        end
      end
    end

    context 'when fetching changes from API' do
      let(:from) { :api }

      let(:mr_changes_array) { [] }

      before do
        allow(instance).to receive(:gitlab).and_return(gitlab_client)

        # The class from the GitLab gem isn't public, so we cannot use verified doubles for it.
        #
        # rubocop:disable RSpec/VerifiedDoubles
        allow(gitlab_client).to receive(:merge_request_changes)
          .with('dummy-project', '1234')
          .and_return(double(changes: mr_changes_array))
        # rubocop:enable RSpec/VerifiedDoubles
      end

      context 'when a file is passed as an argument' do
        it 'calls GitLab API' do
          expect(gitlab_client).to receive(:merge_request_changes)
          .with('dummy-project', '1234')

          subject
        end
      end

      context 'when there are no file changes' do
        let(:mr_changes_array) { [] }

        it 'returns false' do
          expect(subject).to be false
        end
      end

      context 'when there are changes to files other than JS files' do
        let(:mr_changes_array) do
          [
            {
              "new_path" => "scripts/gitlab_component_helpers.sh",
              "old_path" => "scripts/gitlab_component_helpers.sh"
            },
            {
              "new_path" => "scripts/test.js",
              "old_path" => "scripts/test.js"
            }
          ]
        end

        it 'returns false' do
          expect(subject).to be false
        end
      end

      context 'when there are changes only to JS files' do
        let(:mr_changes_array) do
          [
            {
              "new_path" => "scripts/test.js",
              "old_path" => "scripts/test.js"
            }
          ]
        end

        it 'returns true' do
          expect(subject).to be true
        end
      end
    end
  end
end
