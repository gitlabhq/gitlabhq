# frozen_string_literal: true

# Placeholder module for EE implementation needed for CE specs to be run in EE codebase
module LicenseHelpers
  def stub_licensed_features(features)
    # do nothing
  end
end

LicenseHelpers.prepend_mod_with('LicenseHelpers')
