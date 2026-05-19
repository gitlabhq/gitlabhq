# frozen_string_literal: true

# These helpers allow you to manipulate with notes.
#
# Usage:
#   describe "..." do
#     include Features::CanonicalLinkHelpers
#     ...
#
#     expect(page).to have_canonical_link(url)
#
module Features
  module CanonicalLinkHelpers
    def have_canonical_link(url)
      have_xpath("//link[@rel=\"canonical\" and @href=\"#{url}\"]", visible: :hidden)
    end

    def have_any_canonical_links
      have_xpath('//link[@rel="canonical"]', visible: :hidden)
    end
  end
end
