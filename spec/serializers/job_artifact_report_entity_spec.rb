# frozen_string_literal: true

require 'spec_helper'

describe JobArtifactReportEntity do
  let(:report) { create(:ci_job_artifact, :codequality) }
  let(:entity) { described_class.new(report, request: double) }

  describe '#as_json' do
    subject { entity.as_json }

    it 'exposes file_type' do
      expect(subject[:file_type]).to eq(report.file_type)
    end

    it 'exposes file_format' do
      expect(subject[:file_format]).to eq(report.file_format)
    end

    it 'exposes size' do
      expect(subject[:size]).to eq(report.size)
    end

    it 'exposes download path' do
      expect(subject[:download_path]).to include("jobs/#{report.job.id}/artifacts/download?file_type=#{report.file_type}")
    end
  end
end
