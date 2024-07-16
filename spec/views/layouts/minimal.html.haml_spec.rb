# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/minimal', feature_category: :notifications do
  context 'without broadcast messaging' do
    it 'does not render the broadcast layout' do
      render

      expect(rendered).not_to render_template('layouts/_broadcast')
    end
  end
end
