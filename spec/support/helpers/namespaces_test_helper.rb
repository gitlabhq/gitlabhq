# frozen_string_literal: true

module NamespacesTestHelper
  def get_buy_minutes_path(namespace)
    buy_minutes_subscriptions_path(selected_group: namespace.id)
  end

  def get_buy_storage_path(namespace)
    buy_storage_subscriptions_path(selected_group: namespace.id)
  end

  def get_buy_storage_url(namespace)
    buy_storage_subscriptions_url(selected_group: namespace.id)
  end
end

NamespacesTestHelper.prepend_mod
