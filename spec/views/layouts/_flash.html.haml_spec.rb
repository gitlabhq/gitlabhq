# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/_flash', feature_category: :shared do
  let_it_be(:template) { 'layouts/_flash' }
  let_it_be(:flash_container_no_margin_class) { 'flash-container-no-margin' }

  let(:locals) { {} }
  let(:allow_signup) { true }
  let(:current_user) { nil }

  before do
    allow(view).to receive_messages(flash: flash, allow_signup?: allow_signup, current_user: current_user)
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

  describe 'with a hash flash message' do
    context 'with a title' do
      let(:flash) { { 'alert' => { title: 'Something needs your attention', message: 'Here is why' } } }

      it 'renders the title alongside the message' do
        expect(rendered).to have_selector('.gl-alert-title', text: 'Something needs your attention')
        expect(rendered).to have_selector('.gl-alert-body', text: 'Here is why')
      end
    end

    context 'without a title' do
      let(:flash) { { 'alert' => { message: 'Here is why' } } }

      it 'renders the message on its own' do
        expect(rendered).not_to have_selector('.gl-alert-title')
        expect(rendered).to have_selector('.gl-alert-body', text: 'Here is why')
      end
    end

    context 'with an action button' do
      let(:flash) do
        { 'alert' => { message: 'Here is why', button_text: 'Fix it', button_path: '/fix' } }
      end

      it 'renders the button in the alert actions' do
        expect(rendered).to have_selector('.gl-alert-actions a[href="/fix"]', text: 'Fix it')
      end
    end

    context 'with only half of the action button' do
      let(:flash) { { 'alert' => { message: 'Here is why', button_text: 'Fix it' } } }

      it 'renders no button' do
        expect(rendered).not_to have_selector('.gl-alert-actions')
      end
    end
  end

  describe 'with a plain string flash message' do
    let(:flash) { { 'alert' => 'Here is why' } }

    it 'renders the message without a title or actions' do
      expect(rendered).to have_selector('.gl-alert-body', text: 'Here is why')
      expect(rendered).not_to have_selector('.gl-alert-title')
      expect(rendered).not_to have_selector('.gl-alert-actions')
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

    context 'when a user is signed in' do
      let(:current_user) { build_stubbed(:user) }

      it 'does not render the sign in or register banner', :aggregate_failures do
        expect(rendered).not_to include('Sign in or sign up before continuing')
        expect(rendered).not_to have_selector(".btn[href='/users/sign_up']")
      end
    end
  end
end
