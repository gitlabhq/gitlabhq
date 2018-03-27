require 'spec_helper'

describe LfsObjectUploader do
  let(:lfs_object) { create(:lfs_object, :with_file) }
  let(:uploader) { described_class.new(lfs_object, :file) }
  let(:path) { Gitlab.config.lfs.storage_path }

  subject { uploader }

  it_behaves_like "builds correct paths",
                  store_dir: %r[\h{2}/\h{2}],
                  cache_dir: %r[/lfs-objects/tmp/cache],
                  work_dir: %r[/lfs-objects/tmp/work]
end
