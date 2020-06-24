# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

require 'gitlab/danger/emoji_checker'

RSpec.describe Gitlab::Danger::EmojiChecker do
  using RSpec::Parameterized::TableSyntax

  describe '#includes_text_emoji?' do
    where(:text, :includes_emoji) do
      'Hello World!' | false
      ':+1:' | true
      'Hello World! :+1:' | true
    end

    with_them do
      it 'is true when text includes a text emoji' do
        expect(subject.includes_text_emoji?(text)).to be(includes_emoji)
      end
    end
  end

  describe '#includes_unicode_emoji?' do
    where(:text, :includes_emoji) do
      'Hello World!' | false
      '🚀' | true
      'Hello World! 🚀' | true
    end

    with_them do
      it 'is true when text includes a text emoji' do
        expect(subject.includes_unicode_emoji?(text)).to be(includes_emoji)
      end
    end
  end
end
