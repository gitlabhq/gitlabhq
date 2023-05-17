# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Rpm::RepositoryMetadata::BuildFilelistXmlService, feature_category: :package_registry do
  describe '#execute' do
    subject { described_class.new(data).execute }

    include_context 'with rpm package data'

    let(:data) { xml_update_params }
    let(:file_xpath) { "//package/file" }

    it 'adds all file nodes' do
      result = subject

      expect(result.xpath(file_xpath).count).to eq(data[:files].count)
    end

    describe 'setting type attribute' do
      context 'when all files are directories' do
        let(:dirs) do
          3.times.map { generate_directory } # rubocop:disable Performance/TimesMap
        end

        let(:files) do
          5.times.map { FFaker::Filesystem.file_name(dirs.sample) } # rubocop:disable Performance/TimesMap
        end

        let(:data) do
          {
            directories: dirs.map { "#{_1}/" }, # Add trailing slash as in original package
            files: dirs + files
          }
        end

        it 'set dir type attribute for directories only' do
          result = subject

          result.xpath(file_xpath).each do |tag|
            if dirs.include?(tag.content)
              expect(tag.attributes['type']&.value).to eq('dir')
            else
              expect(tag.attributes['type']).to be_nil
            end
          end
        end
      end

      def generate_directory
        FFaker::Lorem.words(3).join('/')
      end
    end
  end
end
