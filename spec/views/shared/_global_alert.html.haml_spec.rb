# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'shared/_global_alert.html.haml' do
  before do
    allow(view).to receive(:sprite_icon).and_return('<span class="icon"></span>'.html_safe)
  end

  it 'renders the title' do
    title = "The alert's title"
    render partial: 'shared/global_alert', locals: { title: title }

    expect(rendered).to have_text(title)
  end

  context 'variants' do
    it 'renders an info alert by default' do
      render

      expect(rendered).to have_selector(".gl-alert-info")
    end

    %w[warning success danger tip].each do |variant|
      it "renders a #{variant} variant" do
        allow(view).to receive(:variant).and_return(variant)
        render partial: 'shared/global_alert', locals: { variant: variant }

        expect(rendered).to have_selector(".gl-alert-#{variant}")
      end
    end
  end

  context 'dismissible option' do
    it 'shows the dismiss button by default' do
      render

      expect(rendered).to have_selector('.gl-dismiss-btn')
    end

    it 'does not show the dismiss button when dismissible is false' do
      render partial: 'shared/global_alert', locals: { dismissible: false }

      expect(rendered).not_to have_selector('.gl-dismiss-btn')
    end
  end
end
