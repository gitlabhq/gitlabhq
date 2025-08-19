# frozen_string_literal: true

require 'tempfile'
require_relative '../../../../../tooling/lib/tooling/mappings/js_to_system_specs_mappings'

RSpec.describe Tooling::Mappings::JsToSystemSpecsMappings, feature_category: :tooling do
  # We set temporary folders, and those readers give access to those folder paths
  attr_accessor :js_base_folder, :system_specs_base_folder

  let(:changed_files) { %w[changed_file1 changed_file2] }

  let(:instance) do
    described_class.new(
      changed_files,
      system_specs_base_folder: system_specs_base_folder,
      js_base_folder: js_base_folder
    )
  end

  around do |example|
    Dir.mktmpdir do |tmp_js_base_folder|
      Dir.mktmpdir do |tmp_system_specs_base_folder|
        self.system_specs_base_folder = tmp_system_specs_base_folder
        self.js_base_folder           = tmp_js_base_folder

        example.run
      end
    end
  end

  describe '#execute' do
    subject { instance.execute }

    context 'when no JS files were changed' do
      let(:changed_files) { [] }

      it 'returns empty array' do
        expect(subject).to be_empty
      end
    end

    context 'when some JS files were changed' do
      let(:changed_files) { ["#{js_base_folder}/issues/secret_values.js"] }

      context 'when the JS files are not present on disk' do
        it 'return empty array' do
          expect(subject).to be_empty
        end
      end

      context 'when the JS files are present on disk' do
        before do
          FileUtils.mkdir_p("#{js_base_folder}/issues")
          File.write("#{js_base_folder}/issues/secret_values.js", "hello")
        end

        context 'when no system specs match the JS keyword' do
          it 'returns empty array' do
            expect(subject).to be_empty
          end
        end

        context 'when a system spec matches the JS keyword' do
          before do
            FileUtils.mkdir_p("#{system_specs_base_folder}/confidential_issues")
            File.write("#{system_specs_base_folder}/confidential_issues/issues_spec.rb", "a test")
          end

          it 'adds the new specs to the output file' do
            expect(subject).to match_array(["#{system_specs_base_folder}/confidential_issues/issues_spec.rb"])
          end
        end
      end
    end
  end

  describe '#filter_files' do
    subject { instance.filter_files }

    before do
      File.write("#{js_base_folder}/index.js", "index.js")
      File.write("#{js_base_folder}/index-with-ee-in-it.js", "index-with-ee-in-it.js")
      File.write("#{js_base_folder}/index-with-jh-in-it.js", "index-with-jh-in-it.js")
    end

    context 'when no files were changed' do
      let(:changed_files) { [] }

      it 'returns an empty array' do
        expect(subject).to be_empty
      end
    end

    context 'when JS files were changed' do
      let(:changed_files) do
        [
          "#{js_base_folder}/index.js",
          "#{js_base_folder}/index-with-ee-in-it.js",
          "#{js_base_folder}/index-with-jh-in-it.js"
        ]
      end

      it 'returns the path to the JS files' do
        # "nil" group represents FOSS JS files in app/assets/javascripts
        expect(subject).to match(nil => [
          "#{js_base_folder}/index.js",
          "#{js_base_folder}/index-with-ee-in-it.js",
          "#{js_base_folder}/index-with-jh-in-it.js"
        ])
      end
    end

    context 'when JS files are deleted' do
      let(:changed_files) { ["#{system_specs_base_folder}/deleted.html"] }

      it 'returns an empty array' do
        expect(subject).to be_empty
      end
    end
  end

  describe '#construct_js_keywords' do
    subject { described_class.new(changed_files).construct_js_keywords(js_files) }

    let(:js_files) do
      %w[
        app/assets/javascripts/boards/issue_board_filters.js
        ee/app/assets/javascripts/queries/epic_due_date.query.graphql
        app/assets/javascripts/protected_branches/constants.js
      ]
    end

    it 'returns a singularized keyword based on the first folder the file is in' do
      expect(subject).to eq(%w[board query protected_branch])
    end

    context 'when the files are under the pages folder' do
      let(:js_files) do
        %w[
          app/assets/javascripts/pages/boards/issue_board_filters.js
          ee/app/assets/javascripts/pages2/queries/epic_due_date.query.graphql
          ee/app/assets/javascripts/queries/epic_due_date.query.graphql
        ]
      end

      it 'captures the second folder' do
        expect(subject).to eq(%w[board pages2 query])
      end
    end
  end

  describe '#system_specs_for_edition' do
    subject do
      instance.system_specs_for_edition(edition)
    end

    let(:edition) { nil }

    context 'when a file is not a ruby spec' do
      before do
        File.write("#{system_specs_base_folder}/issues_spec.tar.gz", "a test")
      end

      it 'does not return that file' do
        expect(subject).to be_empty
      end
    end

    context 'when a file is a ruby spec' do
      let(:spec_pathname) { "#{system_specs_base_folder}/issues_spec.rb" }

      before do
        File.write(spec_pathname, "a test")
      end

      it 'returns that file' do
        expect(subject).to match_array(spec_pathname)
      end
    end

    context 'when FOSS' do
      let(:edition) { nil }

      it 'checks the correct folder' do
        expect(Dir).to receive(:[]).with("#{system_specs_base_folder}/**/*").and_call_original

        subject
      end
    end

    context 'when EE' do
      let(:edition) { 'ee' }

      it 'checks the correct folder' do
        expect(Dir).to receive(:[]).with("ee#{system_specs_base_folder}/**/*").and_call_original

        subject
      end
    end

    context 'when JiHu' do
      let(:edition) { 'jh' }

      it 'checks the correct folder' do
        expect(Dir).to receive(:[]).with("jh#{system_specs_base_folder}/**/*").and_call_original

        subject
      end
    end
  end
end
