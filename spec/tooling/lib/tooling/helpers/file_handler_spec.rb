# frozen_string_literal: true

require 'tempfile'
require_relative '../../../../../tooling/lib/tooling/helpers/file_handler'

class MockClass # rubocop:disable Gitlab/NamespacedClass
  include Tooling::Helpers::FileHandler
end

RSpec.describe Tooling::Helpers::FileHandler, feature_category: :tooling do
  attr_accessor :input_file_path, :output_file_path

  around do |example|
    input_file  = Tempfile.new('input')
    output_file = Tempfile.new('output')

    self.input_file_path  = input_file.path
    self.output_file_path = output_file.path

    # See https://ruby-doc.org/stdlib-1.9.3/libdoc/tempfile/rdoc/
    #     Tempfile.html#class-Tempfile-label-Explicit+close
    begin
      example.run
    ensure
      output_file.close
      input_file.close
      output_file.unlink
      input_file.unlink
    end
  end

  let(:instance)        { MockClass.new }
  let(:initial_content) { 'previous_content1 previous_content2' }

  before do
    # We write into the temp files initially, to later check how the code modified those files
    File.write(input_file_path, initial_content)
    File.write(output_file_path, initial_content)
  end

  describe '#read_array_from_file' do
    subject { instance.read_array_from_file(input_file_path) }

    context 'when the input file does not exist' do
      let(:non_existing_input_pathname) { 'tmp/another_file.out' }

      subject { instance.read_array_from_file(non_existing_input_pathname) }

      around do |example|
        example.run
      ensure
        FileUtils.rm_rf(non_existing_input_pathname)
      end

      it 'creates the file' do
        expect { subject }.to change { File.exist?(non_existing_input_pathname) }.from(false).to(true)
      end
    end

    context 'when the input file is not empty' do
      let(:initial_content) { 'previous_content1 previous_content2' }

      it 'returns the content of the file in an array' do
        expect(subject).to eq(initial_content.split(' '))
      end
    end
  end

  describe '#write_array_to_file' do
    let(:content_array) { %w[new_entry] }
    let(:append_flag) { true }

    subject { instance.write_array_to_file(output_file_path, content_array, append: append_flag) }

    context 'when the output file does not exist' do
      let(:non_existing_output_file) { 'tmp/another_file.out' }

      subject { instance.write_array_to_file(non_existing_output_file, content_array) }

      around do |example|
        example.run
      ensure
        FileUtils.rm_rf(non_existing_output_file)
      end

      it 'creates the file' do
        expect { subject }.to change { File.exist?(non_existing_output_file) }.from(false).to(true)
      end
    end

    context 'when the output file is empty' do
      let(:initial_content) { '' }

      it 'writes the correct content to the file' do
        expect { subject }.to change { File.read(output_file_path) }.from('').to(content_array.join(' '))
      end

      context 'when the content array is not sorted' do
        let(:content_array) { %w[new_entry a_new_entry] }

        it 'sorts the array before writing it to file' do
          expect { subject }.to change { File.read(output_file_path) }.from('').to(content_array.sort.join(' '))
        end
      end
    end

    context 'when the output file is not empty' do
      let(:initial_content) { 'previous_content1 previous_content2' }

      it 'appends the correct content to the file' do
        expect { subject }.to change { File.read(output_file_path) }
          .from(initial_content)
          .to((initial_content.split(' ') + content_array).join(' '))
      end

      context 'when the append flag is set to false' do
        let(:append_flag) { false }

        it 'overwrites the previous content' do
          expect { subject }.to change { File.read(output_file_path) }
            .from(initial_content)
            .to(content_array.join(' '))
        end
      end
    end
  end
end
