# frozen_string_literal: true

# remove data-sourcepos from compare
RSpec::Matchers.define :eq_no_sourcepos do |expected|
  include MarkdownHelpers

  match do |actual|
    remove_sourcepos(actual) == expected
  end

  description do
    "equal ignoring sourcepos #{expected}"
  end
end
