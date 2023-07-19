# frozen_string_literal: true

RSpec.shared_examples 'a layout which reflects the preferred language' do
  context 'when changing the a preferred language' do
    before do
      Gitlab::I18n.locale = :es
    end

    after do
      Gitlab::I18n.use_default_locale
    end

    it 'renders the correct `lang` attribute in the html element' do
      render

      expect(rendered).to have_css('html[lang=es]')
    end
  end
end
