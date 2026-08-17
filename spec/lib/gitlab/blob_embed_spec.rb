# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BlobEmbed, feature_category: :markdown do
  describe '.permalink_pattern' do
    let(:sha) { 'a' * 40 }

    def match(url)
      described_class.permalink_pattern.match("#{Gitlab.config.gitlab.url}#{url}")
    end

    it 'captures the (sub)namespace, project, commit, blob path and optional anchor' do
      m = match("/group/sub/project/-/blob/#{sha}/dir/file.rb#L3-6")

      expect(m[:namespace]).to eq('group/sub')
      expect(m[:project]).to eq('project')
      expect(m[:commit]).to eq(sha)
      expect(m[:blob_path]).to eq('dir/file.rb')
      expect(m[:anchor]).to eq('#L3-6')

      expect(match("/group/project/-/blob/#{sha}/file.rb")[:anchor]).to be_nil
    end

    # Permalinks copied from the UI carry the parameters of the page they were
    # copied from, ahead of the line anchor.
    it 'skips a query string without losing the anchor' do
      expect(match("/g/p/-/blob/#{sha}/file.rb?plain=1#L3-6")[:anchor]).to eq('#L3-6')
      expect(match("/g/p/-/blob/#{sha}/file.rb?blame=1&page=2#L3-6")[:anchor]).to eq('#L3-6')
      expect(match("/g/p/-/blob/#{sha}/file.rb?ref_type=heads")[:anchor]).to be_nil
    end

    it 'keeps the query string out of the blob path' do
      expect(match("/g/p/-/blob/#{sha}/file.rb?plain=1#L3-6")[:blob_path]).to eq('file.rb')
    end

    it 'requires a full 40-character SHA1' do
      expect(match("/group/project/-/blob/abcd1234/file.rb")).to be_nil
      expect(match('/group/project/-/blob/master/file.rb')).to be_nil
    end

    it 'only matches a permalink for this instance anchored at the start' do
      expect(described_class.permalink_pattern.match("https://example.com/g/p/-/blob/#{sha}/f")).to be_nil
      expect(match("/g/p/-/blob/#{sha}/f")).to be_present
      expect(described_class.permalink_pattern.match("x#{Gitlab.config.gitlab.url}/g/p/-/blob/#{sha}/f")).to be_nil
    end
  end
end
