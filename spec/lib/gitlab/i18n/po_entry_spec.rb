require 'spec_helper'

describe Gitlab::I18n::PoEntry do
  describe '.build' do
    it 'builds a metadata entry when the msgid is empty' do
      entry = described_class.build(msgid: '')

      expect(entry).to be_kind_of(Gitlab::I18n::MetadataEntry)
    end

    it 'builds a translation entry when the msgid is empty' do
      entry = described_class.build(msgid: 'Hello world')

      expect(entry).to be_kind_of(Gitlab::I18n::TranslationEntry)
    end

  end
end
