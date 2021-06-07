# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Emoji do
  let_it_be(:emojis) { Gemojione.index.instance_variable_get(:@emoji_by_name) }
  let_it_be(:emojis_by_moji) { Gemojione.index.instance_variable_get(:@emoji_by_moji) }
  let_it_be(:emoji_unicode_versions_by_name) { Gitlab::Json.parse(File.read(Rails.root.join('fixtures', 'emojis', 'emoji-unicode-version-map.json'))) }
  let_it_be(:emojis_aliases) { Gitlab::Json.parse(File.read(Rails.root.join('fixtures', 'emojis', 'aliases.json'))) }

  describe '.emojis' do
    it 'returns emojis' do
      current_emojis = described_class.emojis

      expect(current_emojis).to eq(emojis)
    end
  end

  describe '.emojis_by_moji' do
    it 'return emojis by moji' do
      current_emojis_by_moji = described_class.emojis_by_moji

      expect(current_emojis_by_moji).to eq(emojis_by_moji)
    end
  end

  describe '.emojis_unicodes' do
    it 'returns emoji unicodes' do
      emoji_keys = described_class.emojis_unicodes

      expect(emoji_keys).to eq(emojis_by_moji.keys)
    end
  end

  describe '.emojis_names' do
    it 'returns emoji names' do
      emoji_names = described_class.emojis_names

      expect(emoji_names).to eq(emojis.keys)
    end
  end

  describe '.emojis_aliases' do
    it 'returns emoji aliases' do
      emoji_aliases = described_class.emojis_aliases

      expect(emoji_aliases).to eq(emojis_aliases)
    end
  end

  describe '.emoji_filename' do
    it 'returns emoji filename' do
      # "100" => {"unicode"=>"1F4AF"...}
      emoji_filename = described_class.emoji_filename('100')

      expect(emoji_filename).to eq(emojis['100']['unicode'])
    end
  end

  describe '.emoji_unicode_filename' do
    it 'returns emoji unicode filename' do
      emoji_unicode_filename = described_class.emoji_unicode_filename('💯')

      expect(emoji_unicode_filename).to eq(emojis_by_moji['💯']['unicode'])
    end
  end

  describe '.emoji_unicode_version' do
    it 'returns emoji unicode version by name' do
      emoji_unicode_version = described_class.emoji_unicode_version('100')

      expect(emoji_unicode_version).to eq(emoji_unicode_versions_by_name['100'])
    end
  end

  describe '.normalize_emoji_name' do
    it 'returns same name if not found in aliases' do
      emoji_name = described_class.normalize_emoji_name('random')

      expect(emoji_name).to eq('random')
    end

    it 'returns name if name found in aliases' do
      emoji_name = described_class.normalize_emoji_name('small_airplane')

      expect(emoji_name).to eq(emojis_aliases['small_airplane'])
    end
  end

  describe '.emoji_image_tag' do
    it 'returns emoji image tag' do
      emoji_image = described_class.emoji_image_tag('emoji_one', 'src_url')

      expect(emoji_image).to eq("<img class=\"emoji\" src=\"src_url\" title=\":emoji_one:\" alt=\":emoji_one:\" height=\"20\" width=\"20\" align=\"absmiddle\" />")
    end

    it 'escapes emoji image attrs to prevent XSS' do
      xss_payload = "<script>alert(1)</script>"
      escaped_xss_payload = html_escape(xss_payload)

      emoji_image = described_class.emoji_image_tag(xss_payload, 'http://aaa#' + xss_payload)

      expect(emoji_image).to eq("<img class=\"emoji\" src=\"http://aaa##{escaped_xss_payload}\" title=\":#{escaped_xss_payload}:\" alt=\":#{escaped_xss_payload}:\" height=\"20\" width=\"20\" align=\"absmiddle\" />")
    end
  end

  describe '.emoji_exists?' do
    it 'returns true if the name exists' do
      emoji_exists = described_class.emoji_exists?('100')

      expect(emoji_exists).to be_truthy
    end

    it 'returns false if the name does not exist' do
      emoji_exists = described_class.emoji_exists?('random')

      expect(emoji_exists).to be_falsey
    end
  end

  describe '.gl_emoji_tag' do
    it 'returns gl emoji tag if emoji is found' do
      gl_tag = described_class.gl_emoji_tag('small_airplane')

      expect(gl_tag).to eq('<gl-emoji title="small airplane" data-name="airplane_small" data-unicode-version="7.0">🛩</gl-emoji>')
    end

    it 'returns nil if emoji name is not found' do
      gl_tag = described_class.gl_emoji_tag('random')

      expect(gl_tag).to be_nil
    end
  end
end
