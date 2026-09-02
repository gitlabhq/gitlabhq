# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AntiAbuse::AbuseReportUpload, feature_category: :instance_resiliency do
  let_it_be(:upload) do
    create(:upload, model: create(:abuse_report), uploader: 'AttachmentUploader', mount_point: :screenshot)
  end

  it 'issues updates against the abuse_report_uploads partition, not the uploads parent' do
    recorder = ActiveRecord::QueryRecorder.new do
      described_class.where(id: upload.id).update_all(version: 2)
    end

    expect(recorder.log).to include(a_string_matching(/UPDATE\s+"abuse_report_uploads"/))
  end

  it 'reads rows written through Upload' do
    expect(described_class.find(upload.id).model_type).to eq('AbuseReport')
  end
end
