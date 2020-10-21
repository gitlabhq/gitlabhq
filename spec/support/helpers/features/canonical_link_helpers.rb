# frozen_string_literal: true

# These helpers allow you to manipulate with notes.
#
# Usage:
#   describe "..." do
#     include Spec::Support::Helpers::Features::CanonicalLinkHelpers
#     ...
#
#     expect(page).to have_canonical_link(url)
#
module Spec
  module Support
    module Helpers
      module Features
        module CanonicalLinkHelpers
          def have_canonical_link(url)
            have_xpath("//link[@rel=\"canonical\" and @href=\"#{url}\"]", visible: false)
          end

          def have_any_canonical_links
            have_xpath('//link[@rel="canonical"]', visible: false)
          end
        end
      end
    end
  end
end
