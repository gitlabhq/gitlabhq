require 'spec_helper'

describe NamespaceFileUploader do
  let(:group) { build_stubbed(:group) }
  let(:uploader) { described_class.new(group) }

  describe "#store_dir" do
    it "stores in the namespace id directory" do
      expect(uploader.store_dir).to include(group.id.to_s)
    end
  end

  describe ".absolute_path" do
    it "stores in thecorrect directory" do
      upload_record = create(:upload, :namespace_upload, model: group)

      expect(described_class.absolute_path(upload_record))
        .to include("-/system/namespace/#{group.id}")
    end
  end
end
