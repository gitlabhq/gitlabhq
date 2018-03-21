require 'spec_helper'

describe Gitlab::GitalyClient::BlobsStitcher do
  describe 'enumeration' do
    it 'combines segregated blob messages together' do
      messages = [
        OpenStruct.new(oid: 'abcdef1', path: 'path/to/file', size: 1642, revision: 'f00ba7', mode: 0100644, data: "first-line\n"),
        OpenStruct.new(oid: '', data: 'second-line'),
        OpenStruct.new(oid: '', data: '', revision: 'f00ba7', path: 'path/to/non-existent/file'),
        OpenStruct.new(oid: 'abcdef2', path: 'path/to/another-file', size: 2461, revision: 'f00ba8', mode: 0100644, data: "GIF87a\x90\x01".b)
      ]

      blobs = described_class.new(messages).to_a

      expect(blobs.size).to be(2)

      expect(blobs[0].id).to eq('abcdef1')
      expect(blobs[0].mode).to eq('100644')
      expect(blobs[0].name).to eq('file')
      expect(blobs[0].path).to eq('path/to/file')
      expect(blobs[0].size).to eq(1642)
      expect(blobs[0].commit_id).to eq('f00ba7')
      expect(blobs[0].data).to eq("first-line\nsecond-line")
      expect(blobs[0].binary?).to be false

      expect(blobs[1].id).to eq('abcdef2')
      expect(blobs[1].mode).to eq('100644')
      expect(blobs[1].name).to eq('another-file')
      expect(blobs[1].path).to eq('path/to/another-file')
      expect(blobs[1].size).to eq(2461)
      expect(blobs[1].commit_id).to eq('f00ba8')
      expect(blobs[1].data).to eq("GIF87a\x90\x01".b)
      expect(blobs[1].binary?).to be true
    end
  end
end
