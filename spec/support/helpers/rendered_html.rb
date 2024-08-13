# frozen_string_literal: true

module RenderedHtml
  def rendered_html
    if ::Gitlab.next_rails?
      Capybara::Node::Simple.new(rendered.html)
    else
      Capybara::Node::Simple.new(rendered)
    end
  end
end
