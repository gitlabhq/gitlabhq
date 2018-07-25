require 'spec_helper'

describe ImportExportUploader do
  let(:model) { build_stubbed(:import_export_upload) }
  let(:upload) { create(:upload, model: model) }

  subject { described_class.new(model, :import_file)  }

  context "object_store is REMOTE" do
    before do
      stub_uploads_object_storage
    end

    include_context 'with storage', described_class::Store::REMOTE

    it_behaves_like 'builds correct paths',
                    store_dir: %r[import_export_upload/import_file/],
                    upload_path: %r[import_export_upload/import_file/]
  end
end
