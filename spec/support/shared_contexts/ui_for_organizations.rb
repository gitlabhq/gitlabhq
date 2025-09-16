# frozen_string_literal: true

RSpec.shared_context 'when ui_for_organizations_enabled? is false' do
  before do
    stub_feature_flags(
      ui_for_organizations: false,
      opt_out_organizations: true
    )
  end
end

RSpec.configure do |config|
  config.include_context 'when ui_for_organizations_enabled? is false', :ui_for_organizations_disabled
end
