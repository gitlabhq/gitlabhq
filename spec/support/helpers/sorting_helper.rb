# frozen_string_literal: true

# Helper allows you to sort items
#
# Params
#   value - value for sorting
#
# Usage:
#   include SortingHelper
#
#   sorting_by('Oldest updated')
#
module SortingHelper
  def sorting_by(value)
    find('.filter-dropdown-container button.dropdown-menu-toggle').click
    page.within('.content ul.dropdown-menu.dropdown-menu-right li') do
      click_link value
    end
  end

  def nils_last(value)
    NilsLast.new(value)
  end

  class NilsLast
    include Comparable

    attr_reader :value

    delegate :==, :eql?, :hash, to: :value

    def initialize(value)
      @value = value
      @reverse = false
    end

    def <=>(other)
      return unless other.is_a?(self.class)
      return 0 if value.nil? && other.value.nil?
      return 1 if value.nil?
      return -1 if other.value.nil?

      int = value <=> other.value
      @reverse ? -int : int
    end

    def -@
      @reverse = true
      self
    end
  end
end
