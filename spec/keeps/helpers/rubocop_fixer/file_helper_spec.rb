# frozen_string_literal: true

require 'tmpdir'
require 'fast_spec_helper'
require './keeps/helpers/rubocop_fixer/file_helper'

RSpec.describe Keeps::Helpers::RubocopFixer::FileHelper, feature_category: :tooling do
  let(:file_helper) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }
  let(:test_file) { File.join(temp_dir, 'test_rubocop_todo.yml') }

  after do
    FileUtils.remove_entry(temp_dir)
  end

  describe '#remove_first_exclusions' do
    context 'when file has multiple exclusions' do
      let(:file_content) do
        <<~YAML
          RuboCop/SomeRule:
            Description: 'Some rule description'
            Exclude:
              - file1.rb
              - file2.rb
              - file3.rb
              - file4.rb
              - file5.rb
        YAML
      end

      before do
        File.write(test_file, file_content)
      end

      it 'removes the first N exclusions' do
        file_helper.remove_first_exclusions(test_file, 3)

        result = File.read(test_file)
        expect(result).to eq(<<~YAML)
          RuboCop/SomeRule:
            Description: 'Some rule description'
            Exclude:
              - file4.rb
              - file5.rb
        YAML
      end

      it 'removes all exclusions when remove_count equals total exclusions' do
        file_helper.remove_first_exclusions(test_file, 5)

        result = File.read(test_file)
        expect(result).to eq(<<~YAML)
          RuboCop/SomeRule:
            Description: 'Some rule description'
            Exclude:
        YAML
      end

      it 'removes all exclusions when remove_count exceeds total exclusions' do
        file_helper.remove_first_exclusions(test_file, 10)

        result = File.read(test_file)
        expect(result).to eq(<<~YAML)
          RuboCop/SomeRule:
            Description: 'Some rule description'
            Exclude:
        YAML
      end
    end

    context 'when file has no exclusions' do
      let(:file_content) do
        <<~YAML
          RuboCop/SomeRule:
            Description: 'Some rule description'
            Exclude:
        YAML
      end

      before do
        File.write(test_file, file_content)
      end

      it 'leaves file unchanged' do
        original_content = File.read(test_file)
        file_helper.remove_first_exclusions(test_file, 3)

        result = File.read(test_file)
        expect(result).to eq(original_content)
      end
    end

    context 'when remove_count is zero' do
      let(:file_content) do
        <<~YAML
          RuboCop/SomeRule:
            Description: 'Some rule description'
            Exclude:
              - file1.rb
              - file2.rb
        YAML
      end

      before do
        File.write(test_file, file_content)
      end

      it 'leaves file unchanged' do
        original_content = File.read(test_file)
        file_helper.remove_first_exclusions(test_file, 0)

        result = File.read(test_file)
        expect(result).to eq(original_content)
      end
    end

    context 'when file has different indentation patterns' do
      let(:file_content) do
        <<~YAML
          RuboCop/SomeRule:
            Exclude:
            - file1.rb
              - file2.rb
              - file3.rb
        YAML
      end

      before do
        File.write(test_file, file_content)
      end

      it 'handles various indentation patterns' do
        file_helper.remove_first_exclusions(test_file, 2)

        result = File.read(test_file)
        expect(result).to eq(<<~YAML)
          RuboCop/SomeRule:
            Exclude:
              - file3.rb
        YAML
      end
    end

    context 'when file does not exist' do
      it 'raises an error' do
        non_existent_file = File.join(temp_dir, 'non_existent.yml')

        expect { file_helper.remove_first_exclusions(non_existent_file, 1) }
          .to raise_error(Errno::ENOENT)
      end
    end

    context 'when file is empty' do
      before do
        File.write(test_file, '')
      end

      it 'leaves file unchanged' do
        file_helper.remove_first_exclusions(test_file, 3)

        result = File.read(test_file)
        expect(result).to eq('')
      end
    end
  end
end
