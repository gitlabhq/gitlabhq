# frozen_string_literal: true

require 'tempfile'
require 'fileutils'
require_relative '../../../../../tooling/lib/tooling/mappings/view_to_system_specs_mappings'

RSpec.describe Tooling::Mappings::ViewToSystemSpecsMappings, feature_category: :tooling do
  attr_accessor :view_base_folder, :changes_file, :output_file

  let(:instance) { described_class.new(changes_file, output_file, view_base_folder: view_base_folder) }
  let(:changes_file_content)        { "changed_file1 changed_file2" }
  let(:output_file_initial_content) { "previously_added_spec.rb" }

  around do |example|
    self.changes_file        = Tempfile.new('changes')
    self.output_file         = Tempfile.new('output_file')

    # See https://ruby-doc.org/stdlib-1.9.3/libdoc/tempfile/rdoc/
    #     Tempfile.html#class-Tempfile-label-Explicit+close
    begin
      Dir.mktmpdir do |tmp_views_base_folder|
        self.view_base_folder = tmp_views_base_folder
        example.run
      end
    ensure
      changes_file.close
      output_file.close
      changes_file.unlink
      output_file.unlink
    end
  end

  before do
    FileUtils.mkdir_p("#{view_base_folder}/app/views/dashboard")

    # We write into the temp files initially, to check how the code modified those files
    File.write(changes_file, changes_file_content)
    File.write(output_file, output_file_initial_content)
  end

  shared_examples 'writes nothing to the output file' do
    it 'writes nothing to the output file' do
      expect { subject }.not_to change { File.read(changes_file) }
    end
  end

  describe '#execute' do
    subject { instance.execute }

    let(:changed_files)        { ["#{view_base_folder}/app/views/dashboard/my_view.html.haml"] }
    let(:changes_file_content) { changed_files.join(" ") }

    before do
      # We create all of the changed_files, so that they are part of the filtered files
      changed_files.each { |changed_file| FileUtils.touch(changed_file) }
    end

    context 'when the changed files are not view files' do
      let(:changed_files) { ["#{view_base_folder}/app/views/dashboard/my_helper.rb"] }

      it_behaves_like 'writes nothing to the output file'
    end

    context 'when the changed files are view files' do
      let(:changed_files) { ["#{view_base_folder}/app/views/dashboard/my_view.html.haml"] }

      context 'when the view files do not exist on disk' do
        before do
          allow(File).to receive(:exist?).with(changed_files.first).and_return(false)
        end

        it_behaves_like 'writes nothing to the output file'
      end

      context 'when the view files exist on disk' do
        context 'when no feature match the view' do
          # Nothing in this context, because the spec corresponding to `changed_files` doesn't exist

          it_behaves_like 'writes nothing to the output file'
        end

        context 'when there is a feature spec that exactly matches the view' do
          let(:expected_feature_spec) { "#{view_base_folder}/spec/features/dashboard/my_view_spec.rb" }

          before do
            allow(File).to receive(:exist?).and_call_original
            allow(File).to receive(:exist?).with(expected_feature_spec).and_return(true)
          end

          it 'writes that feature spec to the output file' do
            expect { subject }.to change { File.read(output_file) }
                              .from(output_file_initial_content)
                              .to("#{output_file_initial_content} #{expected_feature_spec}")
          end
        end

        context 'when there is a feature spec that matches the parent folder of the view' do
          let(:expected_feature_specs) do
            [
              "#{view_base_folder}/spec/features/dashboard/another_feature_spec.rb",
              "#{view_base_folder}/spec/features/dashboard/other_feature_spec.rb"
            ]
          end

          before do
            FileUtils.mkdir_p("#{view_base_folder}/spec/features/dashboard")

            expected_feature_specs.each do |expected_feature_spec|
              FileUtils.touch(expected_feature_spec)
            end
          end

          it 'writes all of the feature specs for the parent folder to the output file' do
            expect { subject }.to change { File.read(output_file) }
                              .from(output_file_initial_content)
                              .to("#{output_file_initial_content} #{expected_feature_specs.join(' ')}")
          end
        end
      end
    end
  end
end
