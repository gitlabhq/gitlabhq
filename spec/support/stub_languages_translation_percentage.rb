# frozen_string_literal: true

module StubLanguagesTranslationPercentage
  # Stubs the translation percentage of the i18n languages
  #  - When a `blank?` list is given no stubbing is done;
  #  - When the list is not empty, the languages in the list
  #    are stubbed with the given values, any other language
  #    will have the translation percent set to 0;
  def stub_languages_translation_percentage(list = {})
    return if list.blank?

    expect(Gitlab::I18n)
      .to receive(:percentage_translated_for)
      .at_least(:once)
      .and_wrap_original do |_original, code|
        list.with_indifferent_access[code].to_i
      end
  end
end
