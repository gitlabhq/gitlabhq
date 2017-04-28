module FakeBlobHelpers
  class FakeBlob
    include Linguist::BlobHelper

    attr_reader :path, :size, :data, :lfs_oid, :lfs_size

    def initialize(path: 'file.txt', size: 1.kilobyte, data: 'foo', binary: false, lfs: nil)
      @path = path
      @size = size
      @data = data
      @binary = binary

      @lfs_pointer = lfs.present?
      if @lfs_pointer
        @lfs_oid = SecureRandom.hex(20)
        @lfs_size = 1.megabyte
      end
    end

    alias_method :name, :path

    def mode
      nil
    end

    def id
      0
    end

    def binary?
      @binary
    end

    def load_all_data!(repository)
      # No-op
    end

    def lfs_pointer?
      @lfs_pointer
    end

    def truncated?
      false
    end
  end

  def fake_blob(**kwargs)
    Blob.decorate(FakeBlob.new(**kwargs), project)
  end
end
