# frozen_string_literal: true

module I18nHelper
  def with_stubbed_translations(locale, translations_hash, &block)
    original_cached_find = FastGettext.method(:cached_find)

    allow(FastGettext).to receive(:cached_find) do |key|
      if FastGettext.locale.to_s == locale.to_s
        translations_hash.fetch(key) { original_cached_find.call(key) }
      else
        original_cached_find.call(key)
      end
    end

    Gitlab::I18n.with_locale(locale, &block)
  end
end
