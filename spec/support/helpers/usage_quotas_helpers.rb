# frozen_string_literal: true

module UsageQuotasHelpers
  def setup_usage_quotas_env(namespace_id)
    # overridden in EE
  end
end

require_relative '../../../ee/spec/support/helpers/ee/usage_quotas_helpers' if
  GitlabEdition.ee?

UsageQuotasHelpers.prepend_mod_with('UsageQuotasHelpers')
