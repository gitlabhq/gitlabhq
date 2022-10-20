# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/_flash' do
  let_it_be(:template) { 'layouts/_flash' }
  let_it_be(:flash_container_no_margin_class) { 'flash-container-no-margin' }

  let(:locals) { {} }

  before do
    allow(view).to receive(:flash).and_return(flash)
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
end
