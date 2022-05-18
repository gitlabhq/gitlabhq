# frozen_string_literal: true

module SubscriptionPortalHelper
  def staging_customers_url
    'https://customers.staging.gitlab.com'
  end

  def prod_customers_url
    'https://customers.gitlab.com'
  end
end

SubscriptionPortalHelper.prepend_mod
