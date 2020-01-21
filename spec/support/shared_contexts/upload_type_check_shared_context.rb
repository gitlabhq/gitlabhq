# frozen_string_literal: true

# Construct an `uploader` variable that is configured to `check_upload_type`
# with `mime_types` and `extensions`.
shared_context 'uploader with type check' do
  let(:uploader_class) do
    Class.new(GitlabUploader) do
      include UploadTypeCheck::Concern
      storage :file
    end
  end

  let(:mime_types) { nil }
  let(:extensions) { nil }
  let(:uploader) do
    uploader_class.class_exec(mime_types, extensions) do |mime_types, extensions|
      check_upload_type mime_types: mime_types, extensions: extensions
    end
    uploader_class.new(build_stubbed(:user))
  end
end

shared_context 'stubbed MimeMagic mime type detection' do
  let(:mime_type) { '' }
  let(:magic_mime) { mime_type }
  let(:ext_mime) { mime_type }
  before do
    magic_mime_obj = MimeMagic.new(magic_mime)
    ext_mime_obj = MimeMagic.new(ext_mime)
    allow(MimeMagic).to receive(:by_magic).with(anything).and_return(magic_mime_obj)
    allow(MimeMagic).to receive(:by_path).with(anything).and_return(ext_mime_obj)
  end
end
