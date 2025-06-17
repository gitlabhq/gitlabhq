# frozen_string_literal: true

module RenderedHtml
  def rendered_html
    Capybara.string(rendered)
  end
end
