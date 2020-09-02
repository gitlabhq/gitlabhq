# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Utils::Gzip do
  before do
    example_class = Class.new do
      include Gitlab::Utils::Gzip

      def lorem_ipsum
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod "\
        "tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim "\
        "veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea "\
        "commodo consequat. Duis aute irure dolor in reprehenderit in voluptate "\
        "velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat "\
        "cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id "\
        "est laborum."
      end
    end

    stub_const('ExampleClass', example_class)
  end

  subject { ExampleClass.new }

  let(:sample_string) { subject.lorem_ipsum }
  let(:compressed_string) { subject.gzip_compress(sample_string) }

  describe "#gzip_compress" do
    it "compresses data passed to it" do
      expect(compressed_string.length).to be < sample_string.length
    end

    it "returns uncompressed data when encountering Zlib::GzipFile::Error" do
      expect(ActiveSupport::Gzip).to receive(:compress).and_raise(Zlib::GzipFile::Error)

      expect(compressed_string.length).to eq sample_string.length
    end
  end

  describe "#gzip_decompress" do
    let(:decompressed_string) { subject.gzip_decompress(compressed_string) }

    it "decompresses encoded data" do
      expect(decompressed_string).to eq sample_string
    end

    it "returns compressed data when encountering Zlib::GzipFile::Error" do
      expect(ActiveSupport::Gzip).to receive(:decompress).and_raise(Zlib::GzipFile::Error)

      expect(decompressed_string).not_to eq sample_string.length
    end

    it "returns unmodified data when it is determined to be uncompressed" do
      expect(subject.gzip_decompress(sample_string)).to eq sample_string
    end
  end
end
