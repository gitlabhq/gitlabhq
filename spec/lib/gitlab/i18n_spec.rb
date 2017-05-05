require 'spec_helper'

module Gitlab
  describe I18n, lib: true do
    let(:user) { create(:user, preferred_language: 'es') }

    describe '.set_locale' do
      it 'sets the locale based on current user preferred language' do
        Gitlab::I18n.set_locale(user)

        expect(FastGettext.locale).to eq('es')
        expect(::I18n.locale).to eq(:es)
      end
    end

    describe '.reset_locale' do
      it 'resets the locale to the default language' do
        Gitlab::I18n.set_locale(user)

        Gitlab::I18n.reset_locale

        expect(FastGettext.locale).to eq('en')
        expect(::I18n.locale).to eq(:en)
      end
    end
  end
end
