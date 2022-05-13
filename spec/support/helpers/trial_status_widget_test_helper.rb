# frozen_string_literal: true

module TrialStatusWidgetTestHelper
  def purchase_href(group)
    new_subscriptions_path(namespace_id: group.id, plan_id: 'ultimate-plan-id')
  end
end

TrialStatusWidgetTestHelper.prepend_mod
