# frozen_string_literal: true

require_relative '../../../../tooling/lib/tooling/find_changes'
require_relative '../../../support/helpers/stub_env'
require 'json'

RSpec.describe Tooling::FindChanges, feature_category: :tooling do
  include StubENV

  let(:instance) do
    described_class.new(
      output_file: output_file,
      matched_tests_file: matched_tests_file,
      frontend_fixtures_mapping_path: frontend_fixtures_mapping_path
    )
  end

  let(:gitlab_client)                  { double('GitLab') } # rubocop:disable RSpec/VerifiedDoubles
  let(:output_file)                    { 'output.txt' }
  let(:output_file_content)            { 'first_file second_file' }
  let(:matched_tests_file)             { 'matched_tests.txt' }
  let(:frontend_fixtures_mapping_path) { 'frontend_fixtures_mapping.json' }
  let(:file_changes)                   { ['file1.rb', 'file2.rb'] }

  before do
    stub_env(
      'CI_API_V4_URL' => 'gitlab_api_url',
      'CI_MERGE_REQUEST_IID' => '1234',
      'CI_MERGE_REQUEST_PROJECT_PATH' => 'dummy-project',
      'PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE' => 'dummy-token',
      'RSPEC_TESTS_MAPPING_PATH' => '/tmp/does-not-exist.out'
    )

    allow(instance).to receive(:gitlab).and_return(gitlab_client)
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:write)
  end

  describe '#execute' do
    subject { instance.execute }

    context 'when there is no output file' do
      let(:output_file) { nil }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, "An path to an output file must be given as first argument.")
      end
    end

    context 'when an output file is provided' do
      before do
        allow(File).to receive(:exist?).with(output_file).and_return(true)
        allow(File).to receive(:read).with(output_file).and_return(output_file_content)
      end

      it 'does not call GitLab API to retrieve the MR diff' do
        expect(gitlab_client).not_to receive(:merge_request_changes)

        subject
      end

      context 'when there are no file changes' do
        let(:output_file_content) { '' }

        it 'writes an empty string to output file' do
          expect(File).to receive(:write).with(output_file, '')

          subject
        end
      end

      context 'when there are file changes' do
        let(:output_file_content) { 'first_file_changed second_file_changed' }

        it 'writes file changes to output file' do
          expect(File).to receive(:write).with(output_file, output_file_content)

          subject
        end
      end

      context 'when there is no matched tests file' do
        let(:matched_tests_file) { '' }

        it 'does not add frontend fixtures mapping to the output file' do
          expect(File).to receive(:write).with(output_file, output_file_content)

          subject
        end
      end

      context 'when there is no frontend fixture files' do
        let(:frontend_fixtures_mapping_path) { '' }

        it 'does not add frontend fixtures mapping to the output file' do
          expect(File).to receive(:write).with(output_file, output_file_content)

          subject
        end
      end

      context 'when the matched tests file and frontend fixture files are provided' do
        before do
          allow(File).to receive(:exist?).with(matched_tests_file).and_return(true)
          allow(File).to receive(:exist?).with(frontend_fixtures_mapping_path).and_return(true)

          allow(File).to receive(:read).with(matched_tests_file).and_return(matched_tests)
          allow(File).to receive(:read).with(frontend_fixtures_mapping_path).and_return(frontend_fixtures_mapping_json)
        end

        context 'when there are no mappings for the matched tests' do
          let(:matched_tests) { 'match_spec1 match_spec_2' }
          let(:frontend_fixtures_mapping_json) do
            { other_spec: ['other_mapping'] }.to_json
          end

          it 'does not add frontend fixtures mapping to the output file' do
            expect(File).to receive(:write).with(output_file, output_file_content)

            subject
          end
        end

        context 'when there are available mappings for the matched tests' do
          let(:matched_tests) { 'match_spec1 match_spec_2' }
          let(:spec_mappings) { %w[spec1_mapping1 spec1_mapping2] }
          let(:frontend_fixtures_mapping_json) do
            { match_spec1: spec_mappings }.to_json
          end

          it 'adds the frontend fixtures mappings to the output file' do
            expect(File).to receive(:write).with(output_file, "#{output_file_content} #{spec_mappings.join(' ')}")

            subject
          end
        end
      end
    end
  end

  describe '#only_js_files_changed' do
    subject { instance.only_js_files_changed }

    let(:mr_changes_array) { [] }

    before do
      # The class from the GitLab gem isn't public, so we cannot use verified doubles for it.
      #
      # rubocop:disable RSpec/VerifiedDoubles
      allow(gitlab_client).to receive(:merge_request_changes)
        .with('dummy-project', '1234')
        .and_return(double(changes: mr_changes_array))
      # rubocop:enable RSpec/VerifiedDoubles
    end

    context 'when a file is passed as an argument' do
      let(:output_file) { 'output_file.out' }

      it 'does not read the output file' do
        expect(File).not_to receive(:read).with(output_file)

        subject
      end

      it 'calls GitLab API anyways' do
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
