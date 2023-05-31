# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::GitlabSchemaInfo, feature_category: :cell do
  describe '.new' do
    it 'does ensure that name is always symbol' do
      schema_info = described_class.new(name: 'gitlab_main')
      expect(schema_info.name).to eq(:gitlab_main)
    end

    it 'does raise error when using invalid argument' do
      expect { described_class.new(invalid: 'aa') }.to raise_error ArgumentError, /unknown keywords: invalid/
    end
  end

  describe '.load_file' do
    it 'does load YAML file and has file_path specified' do
      file_path = Rails.root.join('db/gitlab_schemas/gitlab_main.yaml')
      schema_info = described_class.load_file(file_path)

      expect(schema_info).not_to be_nil
      expect(schema_info.file_path).to eq(file_path)
    end
  end
end
