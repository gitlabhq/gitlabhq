# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/minimal', feature_category: :notifications do
  context 'without broadcast messaging' do
    it 'does not render the broadcast layout' do
      render

      expect(rendered).not_to render_template('layouts/_broadcast')
    end
  end

  context 'when content_for(:hide_empty_navbar) is present' do
    before do
      view.content_for(:hide_empty_navbar, true)
    end

    it 'does not render the empty navbar layout' do
      render

      expect(rendered).not_to render_template('layouts/header/_empty')
    end
  end
end
