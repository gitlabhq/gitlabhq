# frozen_string_literal: true

require 'tempfile'
require 'fileutils'
require_relative '../../../../../tooling/lib/tooling/mappings/view_to_system_specs_mappings'

RSpec.describe Tooling::Mappings::ViewToSystemSpecsMappings, feature_category: :tooling do
  attr_accessor :view_base_folder

  let(:instance) do
    described_class.new(changed_files, view_base_folder: view_base_folder)
  end

  let(:changed_files_content) { %w[changed_file1 changed_file2] }

  around do |example|
    Dir.mktmpdir do |tmp_views_base_folder|
      self.view_base_folder = tmp_views_base_folder
      example.run
    end
  end

  before do
    FileUtils.mkdir_p("#{view_base_folder}/app/views/dashboard")
  end

  describe '#execute' do
    subject { instance.execute }

    let(:changed_files) { ["#{view_base_folder}/app/views/dashboard/my_view.html.haml"] }

    before do
      # We create all of the changed_files, so that they are part of the filtered files
      changed_files.each { |changed_file| FileUtils.touch(changed_file) }
    end

    context 'when the changed files are view files' do
      let(:changed_files) { ["#{view_base_folder}/app/views/dashboard/my_view.html.haml"] }

      context 'when the view files exist on disk' do
        context 'when there is a feature spec that exactly matches the view' do
          let(:expected_feature_spec) { "#{view_base_folder}/spec/features/dashboard/my_view_spec.rb" }

          before do
            allow(File).to receive(:exist?).and_call_original
            allow(File).to receive(:exist?).with(expected_feature_spec).and_return(true)
          end

          it 'returns feature spec' do
            expect(subject).to match_array([expected_feature_spec])
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

          it 'returns all of the feature specs for the parent folder' do
            expect(subject).to match_array(expected_feature_specs)
          end
        end
      end
    end
  end
end
