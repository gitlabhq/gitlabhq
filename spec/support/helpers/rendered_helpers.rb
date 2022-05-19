# frozen_string_literal: true

module RenderedHelpers
  # Wraps the `rendered` in `expect` to make it the target of an expectation.
  # Designed to read nicely for one-liners.
  # rubocop:disable RSpec/VoidExpect
  def expect_rendered
    render
    expect(rendered)
  end
  # rubocop:enable RSpec/VoidExpect
end
