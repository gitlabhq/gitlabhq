# frozen_string_literal: true

module PolicyHelpers
  def expect_allowed(*permissions)
    aggregate_failures do
      permissions.each { |p| is_expected.to allow_action(p) }
    end
  end

  def expect_disallowed(*permissions)
    aggregate_failures do
      permissions.each do |p|
        expect(Support::AbilityCheck::Checker.ok?(subject, p.to_sym)).to be(true),
          "expected #{subject.class.name} or a policy it delegates to to define :#{p}"
        is_expected.not_to allow_action(p)
      end
    end
  end
end
