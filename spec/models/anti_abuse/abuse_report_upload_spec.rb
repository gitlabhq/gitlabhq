# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AntiAbuse::AbuseReportUpload, feature_category: :instance_resiliency do
  it 'is bound to the abuse_report_uploads partition of uploads' do
    expect(described_class.superclass).to eq(::Upload)
    expect(described_class.table_name).to eq('abuse_report_uploads')
  end

  it 'uses id alone as the primary key' do
    expect(described_class.primary_key).to eq('id')
  end

  it 'reads rows written through Upload' do
    upload = create(:upload, model: create(:abuse_report), uploader: 'AttachmentUploader', mount_point: :screenshot)

    expect(described_class.find(upload.id).model_type).to eq('AbuseReport')
  end
end
