require 'spec_helper'

IDENTIFIER = %r{\h+/\S+}

describe NamespaceFileUploader do
  let(:group) { build_stubbed(:group) }
  let(:uploader) { described_class.new(group) }
  let(:upload) { create(:upload, :namespace_upload, model: group) }

  subject { uploader }

  it_behaves_like 'builds correct paths',
                  store_dir: %r[uploads/-/system/namespace/\d+],
                  upload_path: IDENTIFIER,
                  absolute_path: %r[#{CarrierWave.root}/uploads/-/system/namespace/\d+/#{IDENTIFIER}]

  # EE-specific
  context "object_store is REMOTE" do
    before do
      stub_uploads_object_storage
    end

    include_context 'with storage', described_class::Store::REMOTE

    it_behaves_like 'builds correct paths',
                    store_dir: %r[namespace/\d+/\h+],
                    upload_path: IDENTIFIER
  end
end
