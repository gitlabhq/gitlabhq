# frozen_string_literal: true

module FakeBlobHelpers
  class FakeBlob
    include BlobLike

    attr_reader :path, :size, :data, :lfs_oid, :lfs_size, :mode

    def initialize(path: 'file.txt', size: 1.kilobyte, data: 'foo', binary: false, lfs: nil, mode: nil)
      @path = path
      @size = size
      @data = data
      @binary = binary
      @mode = mode

      @lfs_pointer = lfs.present?
      if @lfs_pointer
        @lfs_oid = SecureRandom.hex(20)
        @lfs_size = 1.megabyte
      end
    end

    alias_method :name, :path

    def id
      "00000000"
    end

    def commit_id
      "11111111"
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
    container = kwargs.delete(:container) || project

    Blob.decorate(FakeBlob.new(**kwargs), container)
  end
end
