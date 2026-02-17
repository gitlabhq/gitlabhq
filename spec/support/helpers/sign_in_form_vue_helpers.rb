# frozen_string_literal: true

module SignInFormVueHelpers
  # Temporarily run specs with `sign_in_form_vue` feature flag enabled and disabled.
  # Will be removed when `sign_in_form_vue` feature flag is removed.
  def with_and_without_sign_in_form_vue(&block)
    context "with sign_in_form_vue feature flag disabled" do
      before do
        stub_feature_flags(sign_in_form_vue: false)
      end

      module_eval(&block)
    end

    context "with sign_in_form_vue feature flag enabled", :js do
      module_eval(&block)
    end
  end
end

RSpec.configure do |config|
  config.extend SignInFormVueHelpers, type: :feature
end
