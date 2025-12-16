# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../scripts/database/loose_foreign_keys_ordering_checker'

RSpec.describe LooseForeignKeysOrderingChecker, feature_category: :database do
  let(:yaml_path) { described_class::LOOSE_FOREIGN_KEYS_PATH }
  let(:checker) { described_class.new }

  around do |example|
    # Backup the original file if it exists
    original_content = File.exist?(yaml_path) ? File.read(yaml_path) : nil

    example.run
  ensure
    # Restore the original file
    if original_content
      File.write(yaml_path, original_content)
    else
      FileUtils.rm_f(yaml_path)
    end
  end

  describe '#check' do
    context 'when file does not exist' do
      before do
        allow(File).to receive(:exist?).with(yaml_path).and_return(false)
      end

      it 'returns an error result' do
        result = checker.check

        expect(result).to be_a(described_class::Result)
        expect(result.error_code).to eq(described_class::ERROR_CODE)
        expect(result.error_message).to include('not found')
      end
    end

    context 'when file is empty' do
      before do
        File.write(yaml_path, "---\n")
      end

      it 'returns nil (no error)' do
        expect(checker.check).to be_nil
      end
    end

    context 'when tables are in correct alphabetical order' do
      before do
        yaml_content = <<~YAML
          ---
          ai_conversation_messages:
            - table: ai_conversation_threads
              column: thread_id
              on_delete: async_delete
          projects:
            - table: users
              column: creator_id
              on_delete: async_nullify
          users:
            - table: namespaces
              column: namespace_id
              on_delete: async_delete
        YAML
        File.write(yaml_path, yaml_content)
      end

      it 'returns nil (no error)' do
        expect(checker.check).to be_nil
      end
    end

    context 'when tables are not in alphabetical order' do
      before do
        yaml_content = <<~YAML
          ---
          users:
            - table: namespaces
              column: namespace_id
              on_delete: async_delete
          projects:
            - table: users
              column: creator_id
              on_delete: async_nullify
          ai_conversation_messages:
            - table: ai_conversation_threads
              column: thread_id
              on_delete: async_delete
        YAML
        File.write(yaml_path, yaml_content)
      end

      it 'returns an error result with details' do
        result = checker.check

        expect(result).to be_a(described_class::Result)
        expect(result.error_code).to eq(described_class::ERROR_CODE)
        expect(result.error_message).to include('not in alphabetical order')
        expect(result.error_message).to include('projects')
        expect(result.error_message).to include('ai_conversation_messages')
      end
    end

    context 'when there are multiple misordered tables' do
      before do
        yaml_content = <<~YAML
          ---
          zebra:
            - table: something
              column: id
              on_delete: async_delete
          apple:
            - table: something
              column: id
              on_delete: async_delete
          banana:
            - table: something
              column: id
              on_delete: async_delete
        YAML
        File.write(yaml_path, yaml_content)
      end

      it 'reports all misordered tables' do
        result = checker.check

        expect(result.error_message).to include('zebra')
        expect(result.error_message).to include('apple')
      end
    end
  end
end
