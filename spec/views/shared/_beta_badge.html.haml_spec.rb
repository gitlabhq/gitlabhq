# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/_beta_badge.html.haml', feature_category: :shared do
  it 'renders without style when no style is provided' do
    render partial: 'shared/beta_badge'

    # The span should have an empty class attribute when no style is provided
    expect(rendered).to include('span class=""')
    expect(rendered).to have_content('Beta')
  end

  it 'renders with style when style is provided' do
    render partial: 'shared/beta_badge', locals: { style: 'custom-class' }

    expect(rendered).to have_css('span.custom-class')
    expect(rendered).to have_content('Beta')
  end
end
