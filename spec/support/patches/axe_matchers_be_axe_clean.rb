# frozen_string_literal: true

# We have a rubocop rule to enforce the use of the within_testid feature spec
# helper, but currently it does not work with the accessibility test matcher
# be_axe_clean. This patch allows the be_axe_clean matcher to accept
# within_testid helper.

module Axe
  module Matchers
    class BeAxeClean
      def within_testid(testid)
        within("[data-testid=\"#{testid}\"]")
      end
    end
  end
end
