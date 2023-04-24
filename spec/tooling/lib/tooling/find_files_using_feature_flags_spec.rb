# frozen_string_literal: true

require 'tempfile'
require_relative '../../../../tooling/lib/tooling/find_files_using_feature_flags'

RSpec.describe Tooling::FindFilesUsingFeatureFlags, feature_category: :tooling do
  attr_accessor :changed_files_file

  let(:changed_files_pathname) { changed_files_file.path }
  let(:instance)               { described_class.new(changed_files_pathname: changed_files_pathname) }
  let(:changed_files_content)  { '' }

  around do |example|
    self.changed_files_file = Tempfile.new('changed_files_file')

    # See https://ruby-doc.org/stdlib-1.9.3/libdoc/tempfile/rdoc/
    #     Tempfile.html#class-Tempfile-label-Explicit+close
    begin
      example.run
    ensure
      changed_files_file.close
      changed_files_file.unlink
    end
  end

  before do
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:read).and_call_original

    File.write(changed_files_pathname, changed_files_content)
  end

  describe '#execute' do
    subject { instance.execute }

    let(:valid_ff_pathname_1)     { 'config/feature_flags/development/my_feature_flag.yml' }
    let(:valid_ff_pathname_2)     { 'config/feature_flags/development/my_other_feature_flag.yml' }
    let(:changed_files_content) { "#{valid_ff_pathname_1} #{valid_ff_pathname_2}" }
    let(:ruby_files)            { [] }

    before do
      allow(File).to receive(:exist?).with(valid_ff_pathname_1).and_return(true)
      allow(File).to receive(:exist?).with(valid_ff_pathname_2).and_return(true)
      allow(Dir).to receive(:[]).with('**/*.rb').and_return(ruby_files)
    end

    context 'when no ruby files are using the modified feature flag' do
      let(:ruby_files) { [] }

      it 'does not add anything to the input file' do
        expect { subject }.not_to change { File.read(changed_files_pathname) }
      end
    end

    context 'when some ruby files are using the modified feature flags' do
      let(:matching_ruby_file_1)   { 'first-ruby-file' }
      let(:matching_ruby_file_2)   { 'second-ruby-file' }
      let(:not_matching_ruby_file) { 'third-ruby-file' }
      let(:ruby_files)             { [matching_ruby_file_1, matching_ruby_file_2, not_matching_ruby_file] }

      before do
        allow(File).to receive(:read).with(matching_ruby_file_1).and_return('my_feature_flag')
        allow(File).to receive(:read).with(matching_ruby_file_2).and_return('my_other_feature_flag')
        allow(File).to receive(:read).with(not_matching_ruby_file).and_return('other text')
      end

      it 'add the matching ruby files to the input file' do
        expect { subject }.to change { File.read(changed_files_pathname) }
          .from(changed_files_content)
          .to("#{changed_files_content} #{matching_ruby_file_1} #{matching_ruby_file_2}")
      end
    end
  end

  describe '#filter_files' do
    subject { instance.filter_files }

    let(:changed_files_content) { path_to_file }

    context 'when the file does not exist on disk' do
      let(:path_to_file) { "config/other_feature_flags_folder/feature.yml" }

      before do
        allow(File).to receive(:exist?).with(path_to_file).and_return(false)
      end

      it 'returns an empty array' do
        expect(subject).to be_empty
      end
    end

    context 'when the file exists on disk' do
      before do
        allow(File).to receive(:exist?).with(path_to_file).and_return(true)
      end

      context 'when the file is not in the features folder' do
        let(:path_to_file) { "config/other_folder/development/feature.yml" }

        it 'returns an empty array' do
          expect(subject).to be_empty
        end
      end

      context 'when the filename does not have the correct extension' do
        let(:path_to_file) { "config/feature_flags/development/feature.rb" }

        it 'returns an empty array' do
          expect(subject).to be_empty
        end
      end

      context 'when the ruby file uses a valid feature flag file' do
        let(:path_to_file) { "config/feature_flags/development/feature.yml" }

        it 'returns the file' do
          expect(subject).to match_array(path_to_file)
        end
      end
    end
  end
end
