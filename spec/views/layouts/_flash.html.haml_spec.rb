# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/_flash', feature_category: :shared do
  let_it_be(:template) { 'layouts/_flash' }
  let_it_be(:flash_container_no_margin_class) { 'flash-container-no-margin' }

  let(:locals) { {} }
  let(:allow_signup) { true }

  before do
    allow(view).to receive_messages(flash: flash, allow_signup?: allow_signup)
    render(template: template, locals: locals)
  end

  describe 'default' do
    it 'does not render flash container no margin class' do
      expect(rendered).not_to have_selector(".#{flash_container_no_margin_class}")
    end
  end

  describe 'closable flash messages' do
    where(:flash_type) do
      %w[alert notice success]
    end

    with_them do
      let(:flash) { { flash_type => 'This is a closable flash message' } }

      it 'shows a close button' do
        expect(rendered).to include('js-close')
      end
    end
  end

  describe 'non closable flash messages' do
    where(:flash_type) do
      %w[error message toast warning]
    end

    with_them do
      let(:flash) { { flash_type => 'This is a non closable flash message' } }

      it 'does not show a close button' do
        expect(rendered).not_to include('js-close')
      end
    end
  end

  describe 'with flash_class in locals' do
    let(:locals) { { flash_container_no_margin: true } }

    it 'adds class to flash-container' do
      expect(rendered).to have_selector(".flash-container.#{flash_container_no_margin_class}")
    end
  end

  describe 'with Warden timedout flash message' do
    let(:flash) { { 'timedout' => true } }

    it 'does not render info box with the word true in it' do
      expect(rendered).not_to include('true')
    end
  end

  describe 'with Devise unauthenticated message' do
    let(:flash) { { flash_type: I18n.t('devise.failure.unauthenticated') } }

    it 'renders message with registration button' do
      expect(rendered).to include('Sign in or sign up before continuing')
      expect(rendered).not_to include('js-close')
      expect(rendered).to have_selector(".btn[href='/users/sign_up']")
    end

    context 'when signup is disabled' do
      let(:allow_signup) { false }

      it 'renders message without registration button' do
        expect(rendered).to include('Sign in before continuing.')
        expect(rendered).not_to include('Sign in or sign up before continuing')
        expect(rendered).not_to include('Register now')
        expect(rendered).not_to have_selector(".btn[href='/users/sign_up']")
      end
    end
  end
end
