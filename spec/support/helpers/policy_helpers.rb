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

  # Checks `subject` allows nothing a signed-in user with no membership isn't
  # also allowed on the same resource, across every ability the policy defines.
  def expect_no_permissions_beyond_non_member
    non_member = described_class.new(build_stubbed(:user), subject.subject)
    extra = allowed_abilities(subject) - allowed_abilities(non_member)

    expect(extra).to be_empty, "expected no permissions beyond a non-member's, got #{extra.sort}"
  end

  def allowed_abilities(policy)
    policy.class.ability_map.map.keys.select { |ability| policy.allowed?(ability) }
  end
end
