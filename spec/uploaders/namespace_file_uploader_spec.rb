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
end
