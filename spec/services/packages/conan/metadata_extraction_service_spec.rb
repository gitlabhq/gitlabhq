# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Conan::MetadataExtractionService, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  # We use `let` instead of `let_it_be` for these fixtures because multiple contexts
  # modify `package_file.file` in their `before` blocks. With `let_it_be`, these
  # in-memory modifications persist across examples, causing test pollution.
  # For example, if "with invalid conaninfo.txt" tests run before "with database error"
  # tests, the package_file still contains the invalid fixture, causing wrong errors.
  # Using `let` ensures each example gets a fresh package_file instance.
  let(:package_reference) { create(:conan_package_reference, info: {}) }
  let(:package_file) do
    create(:conan_package_file, :conan_package_info, conan_package_reference: package_reference)
  end

  describe '#execute' do
    subject(:service) { described_class.new(package_file).execute }

    describe 'parsing conaninfo files' do
      let(:expected_metadata) do
        Gitlab::Json.parse(fixture_file_upload("spec/fixtures/packages/conan/parsed_conaninfo/#{expected_json}").read)
      end

      where(:conaninfo_fixture, :expected_json) do
        'conaninfo.txt'         | 'conaninfo.json'
        'conaninfo_minimal.txt' | 'conaninfo_minimal.json'
      end

      with_them do
        before do
          package_file.file = fixture_file_upload("spec/fixtures/packages/conan/package_files/#{conaninfo_fixture}")
        end

        it 'updates the package reference info', :aggregate_failures do
          expect { service }
            .to change { package_file.conan_file_metadatum.package_reference.reload.info }
            .from({})
            .to(expected_metadata)
        end
      end
    end

    context 'with database error' do
      # rubocop:disable Layout/LineLength -- Required for formatting of table
      where(:database_error_message, :expected_error_message) do
        'Info conaninfo is too large. Maximum size is 20000 characters' | 'conaninfo.txt file too large'
        'Test error'                                                    | 'conaninfo.txt metadata failedto be saved: Test error'
      end
      # rubocop:enable Layout/LineLength

      with_them do
        before do
          allow(package_reference).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(package_reference))
          allow(package_reference).to receive_message_chain(:errors,
            :full_messages).and_return([database_error_message])
        end

        it 'raises ExtractionError and does not update package reference info' do
          expect { service }
            .to raise_error(described_class::ExtractionError, expected_error_message)
            .and not_change { package_reference.reload.info }
        end
      end
    end

    context 'with invalid conaninfo.txt' do
      # rubocop:disable Layout/LineLength -- Required for formatting of table
      where(:conaninfo_fixture, :expected_error) do
        'conaninfo_invalid_line.txt'        | 'Error while parsing conaninfo.txt: Invalid key-value line: test='
        'conaninfo_invalid_recipe_hash.txt' | 'Error while parsing conaninfo.txt: The recipe_hash section cannot have multiple lines'
        'conaninfo_invalid_section.txt'     | 'Error while parsing conaninfo.txt: Invalid section header: [missing_bracket'
      end
      # rubocop:enable Layout/LineLength

      with_them do
        before do
          package_file.file = fixture_file_upload("spec/fixtures/packages/conan/package_files/#{conaninfo_fixture}")
        end

        it 'raises ExtractionError and does not update package reference info' do
          expect { service }
            .to raise_error(described_class::ExtractionError, expected_error)
            .and not_change { package_file.conan_file_metadatum.package_reference.reload.info }
        end
      end
    end
  end
end
