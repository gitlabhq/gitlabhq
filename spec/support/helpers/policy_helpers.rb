# frozen_string_literal: true

module PolicyHelpers
  def expect_allowed(*permissions)
    aggregate_failures do
      permissions.each { |p| is_expected.to be_allowed(p) }
    end
  end

  def expect_disallowed(*permissions)
    aggregate_failures do
      permissions.each { |p| is_expected.not_to be_allowed(p) }
    end
  end
end
