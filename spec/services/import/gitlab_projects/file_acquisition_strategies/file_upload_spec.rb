# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Import::GitlabProjects::FileAcquisitionStrategies::FileUpload, :aggregate_failures, feature_category: :importers do
  let(:file) { UploadedFile.new(File.join('spec', 'features', 'projects', 'import_export', 'test_project_export.tar.gz')) }

  describe 'validation' do
    it 'validates presence of file' do
      valid = described_class.new(params: { file: file })
      expect(valid).to be_valid

      invalid = described_class.new(params: {})
      expect(invalid).not_to be_valid
      expect(invalid.errors.full_messages).to include("File must be uploaded")
    end
  end

  describe '#project_params' do
    it 'returns the file to upload in the params' do
      subject = described_class.new(params: { file: file })

      expect(subject.project_params).to eq(file: file)
    end
  end
end
