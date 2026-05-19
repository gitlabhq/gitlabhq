# frozen_string_literal: true

module RenderedHelpers
  # Wraps the `rendered` in `expect` to make it the target of an expectation.
  # Designed to read nicely for one-liners.
  def expect_rendered
    render
    expect(rendered)
  end
end
