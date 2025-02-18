# frozen_string_literal: true

require 'tempfile'
require_relative '../../../../../tooling/lib/tooling/mappings/graphql_base_type_mappings'

RSpec.describe Tooling::Mappings::GraphqlBaseTypeMappings, feature_category: :tooling do
  # We set temporary folders, and those readers give access to those folder paths
  attr_accessor :foss_folder, :ee_folder, :jh_folder
  attr_accessor :changed_files_file, :predictive_tests_file

  let(:changed_files_pathname)           { changed_files_file.path }
  let(:predictive_tests_pathname)        { predictive_tests_file.path }
  let(:instance)                         { described_class.new(changed_files_pathname, predictive_tests_pathname) }
  let(:changed_files_content)            { "changed_file1 changed_file2" }
  let(:predictive_tests_initial_content) { "previously_matching_spec.rb" }

  around do |example|
    self.changed_files_file    = Tempfile.new('changed_files_file')
    self.predictive_tests_file = Tempfile.new('predictive_tests_file')

    Dir.mktmpdir('FOSS') do |foss_folder|
      Dir.mktmpdir('EE') do |ee_folder|
        Dir.mktmpdir('JH') do |jh_folder|
          self.foss_folder = foss_folder
          self.ee_folder   = ee_folder
          self.jh_folder   = jh_folder

          # See https://ruby-doc.org/stdlib-1.9.3/libdoc/tempfile/rdoc/
          #     Tempfile.html#class-Tempfile-label-Explicit+close
          begin
            example.run
          ensure
            changed_files_file.close
            predictive_tests_file.close
            changed_files_file.unlink
            predictive_tests_file.unlink
          end
        end
      end
    end
  end

  before do
    stub_const("Tooling::Mappings::GraphqlBaseTypeMappings::GRAPHQL_TYPES_FOLDERS", {
      nil => [foss_folder],
      'ee' => [foss_folder, ee_folder],
      'jh' => [foss_folder, ee_folder, jh_folder]
    })

    # We write into the temp files initially, to later check how the code modified those files
    File.write(changed_files_pathname, changed_files_content)
    File.write(predictive_tests_pathname, predictive_tests_initial_content)
  end

  describe '#execute' do
    subject { instance.execute }

    context 'when no GraphQL files were changed' do
      let(:changed_files_content) { '' }

      it 'does not change the output file' do
        expect { subject }.not_to change { File.read(predictive_tests_pathname) }
      end
    end

    context 'when some GraphQL files were changed' do
      let(:changed_files_content) do
        [
          "#{foss_folder}/my_graphql_file.rb",
          "#{foss_folder}/my_other_graphql_file.rb"
        ].join(' ')
      end

      context 'when none of those GraphQL types are included in other GraphQL types' do
        before do
          File.write("#{foss_folder}/my_graphql_file.rb", "some graphQL code; implements-test MyOtherGraphqlFile")
          File.write("#{foss_folder}/my_other_graphql_file.rb", "some graphQL code")
        end

        it 'does not change the output file' do
          expect { subject }.not_to change { File.read(predictive_tests_pathname) }
        end
      end

      context 'when the GraphQL types are included in other GraphQL types' do
        before do
          File.write("#{foss_folder}/my_graphql_file.rb", "some graphQL code; implements MyOtherGraphqlFile")
          File.write("#{foss_folder}/my_other_graphql_file.rb", "some graphQL code")

          # We mock this because we are using temp directories, so we cannot rely on just replacing `app`` with `spec`
          allow(instance).to receive(:filename_to_spec_filename)
            .with("#{foss_folder}/my_graphql_file.rb")
            .and_return('spec/my_graphql_file_spec.rb')
        end

        it 'writes the correct specs in the output' do
          expect { subject }.to change { File.read(predictive_tests_pathname) }
                            .from(predictive_tests_initial_content)
                            .to("#{predictive_tests_initial_content} spec/my_graphql_file_spec.rb")
        end
      end
    end
  end

  describe '#filter_files' do
    subject { instance.filter_files }

    before do
      File.write("#{foss_folder}/my_graphql_file.rb", "my_graphql_file.rb")
      File.write("#{foss_folder}/my_other_graphql_file.rb", "my_other_graphql_file.rb")
      File.write("#{foss_folder}/another_file.erb", "another_file.erb")
    end

    context 'when no files were changed' do
      let(:changed_files_content) { '' }

      it 'returns an empty array' do
        expect(subject).to be_empty
      end
    end

    context 'when GraphQL files were changed' do
      let(:changed_files_content) do
        [
          "#{foss_folder}/my_graphql_file.rb",
          "#{foss_folder}/my_other_graphql_file.rb",
          "#{foss_folder}/another_file.erb"
        ].join(' ')
      end

      it 'returns the path to the GraphQL files' do
        expect(subject).to match_array([
          "#{foss_folder}/my_graphql_file.rb",
          "#{foss_folder}/my_other_graphql_file.rb"
        ])
      end
    end

    context 'when files are deleted' do
      let(:changed_files_content) { "#{foss_folder}/deleted.rb" }

      it 'returns an empty array' do
        expect(subject).to be_empty
      end
    end
  end

  describe '#types_hierarchies' do
    subject { instance.types_hierarchies }

    context 'when no types are implementing other types' do
      before do
        File.write("#{foss_folder}/foss_file.rb", "some graphQL code")
        File.write("#{ee_folder}/ee_file.rb", "some graphQL code")
        File.write("#{jh_folder}/jh_file.rb", "some graphQL code")
      end

      it 'returns nothing' do
        expect(subject).to eq(
          nil => {},
          'ee' => {},
          'jh' => {}
        )
      end
    end

    context 'when types are implementing other types' do
      before do
        File.write("#{foss_folder}/foss_file.rb", "some graphQL code; implements NoteableInterface")
        File.write("#{ee_folder}/ee_file.rb", "some graphQL code; implements NoteableInterface")
        File.write("#{jh_folder}/jh_file.rb", "some graphQL code; implements NoteableInterface")
      end

      context 'when FOSS' do
        it 'returns only FOSS types' do
          expect(subject).to include(
            nil => {
              'NoteableInterface' => [
                "#{foss_folder}/foss_file.rb"
              ]
            }
          )
        end
      end

      context 'when EE' do
        it 'returns the correct children types' do
          expect(subject).to include(
            'ee' => {
              'NoteableInterface' => [
                "#{foss_folder}/foss_file.rb",
                "#{ee_folder}/ee_file.rb"
              ]
            }
          )
        end
      end

      context 'when JH' do
        it 'returns the correct children types' do
          expect(subject).to include(
            'jh' => {
              'NoteableInterface' => [
                "#{foss_folder}/foss_file.rb",
                "#{ee_folder}/ee_file.rb",
                "#{jh_folder}/jh_file.rb"
              ]
            }
          )
        end
      end
    end
  end

  describe '#filename_to_class_name' do
    let(:filename) { 'app/graphql/types/user_merge_request_interaction_type.rb' }

    subject { instance.filename_to_class_name(filename) }

    it 'returns the correct class name' do
      expect(subject).to eq('UserMergeRequestInteractionType')
    end
  end

  describe '#filename_to_spec_filename' do
    let(:filename)               { 'ee/app/graphql/ee/types/application_type.rb' }
    let(:expected_spec_filename) { 'ee/spec/graphql/ee/types/application_type_spec.rb' }

    subject { instance.filename_to_spec_filename(filename) }

    context 'when the spec file exists' do
      before do
        allow(File).to receive(:exist?).with(expected_spec_filename).and_return(true)
      end

      it 'returns the correct spec filename' do
        expect(subject).to eq(expected_spec_filename)
      end
    end

    context 'when the spec file does not exist' do
      before do
        allow(File).to receive(:exist?).with(expected_spec_filename).and_return(false)
      end

      it 'returns nil' do
        expect(subject).to eq(nil)
      end
    end
  end
end
