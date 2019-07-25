# frozen_string_literal: true

module FakeBlobHelpers
  class FakeBlob
    include BlobLike

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

    def id
      0
    end

    def binary_in_repo?
      @binary
    end

    def external_storage
      :lfs if @lfs_pointer
    end

    alias_method :external_size, :lfs_size
  end

  def fake_blob(**kwargs)
    Blob.decorate(FakeBlob.new(**kwargs), project)
  end
end
