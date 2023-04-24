# frozen_string_literal: true

# This shared context requires:
# - factory: either :debian_project_distribution or :debian_group_distribution
# - can_freeze: whether to freeze the created object or not
RSpec.shared_context 'for Debian Distribution' do |factory, can_freeze|
  let_it_be(:distribution_with_suite, freeze: can_freeze) { create(factory, :with_suite) }
  let_it_be(:distribution_with_same_container, freeze: can_freeze) do
    create(factory, container: distribution_with_suite.container)
  end

  let_it_be(:distribution_with_same_codename, freeze: can_freeze) do
    create(factory, codename: distribution_with_suite.codename)
  end

  let_it_be(:distribution_with_same_suite, freeze: can_freeze) { create(factory, suite: distribution_with_suite.suite) }
  let_it_be(:distribution_with_codename_and_suite_flipped, freeze: can_freeze) do
    create(factory, codename: distribution_with_suite.suite, suite: distribution_with_suite.codename)
  end

  let_it_be_with_refind(:distribution) { create(factory, container: distribution_with_suite.container) }
end
