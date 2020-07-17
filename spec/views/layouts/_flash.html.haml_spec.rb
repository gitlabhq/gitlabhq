# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/_flash' do
  before do
    allow(view).to receive(:flash).and_return(flash)
    render
  end

  describe 'closable flash messages' do
    %w(alert notice success).each do |flash_type|
      let(:flash) { { flash_type => 'This is a closable flash message' } }

      it 'shows a close button' do
        expect(rendered).to include('js-close-icon')
      end
    end
  end

  describe 'non closable flash messages' do
    %w(error message toast warning).each do |flash_type|
      let(:flash) { { flash_type => 'This is a non closable flash message' } }

      it 'shows a close button' do
        expect(rendered).not_to include('js-close-icon')
      end
    end
  end
end
