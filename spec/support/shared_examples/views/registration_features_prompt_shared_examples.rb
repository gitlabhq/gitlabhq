# frozen_string_literal: true

# Returns the Capybara node to assert against so these shared examples work in
# both view specs and feature specs.
#
# - View specs (`type: :view`) render the template and assert on `rendered`.
# - Feature specs assert on Capybara's `page`; the caller is expected to have
#   already visited the page before invoking the shared example.
RSpec.shared_context 'with registration features prompt subject' do
  let(:registration_features_prompt_subject) do
    if RSpec.current_example.metadata[:type] == :view
      render
      rendered
    else
      page
    end
  end
end

RSpec.shared_examples 'renders registration features prompt' do |disabled_field|
  include_context 'with registration features prompt subject'

  it 'renders a placeholder input with registration features message', :aggregate_failures do
    if disabled_field
      expect(registration_features_prompt_subject).to have_field(disabled_field, disabled: true)
    end

    expect(registration_features_prompt_subject).to have_content(format(s_("RegistrationFeatures|Want to %{feature_title} for free?"), feature_title: s_('RegistrationFeatures|use this feature')))
    expect(registration_features_prompt_subject).to have_link(s_('RegistrationFeatures|Registration Features Program'))
  end
end

RSpec.shared_examples 'does not render registration features prompt' do |disabled_field|
  include_context 'with registration features prompt subject'

  it 'does not render a placeholder input with registration features message', :aggregate_failures do
    if disabled_field
      expect(registration_features_prompt_subject).not_to have_field(disabled_field, disabled: true)
    end

    expect(registration_features_prompt_subject).not_to have_content(format(s_("RegistrationFeatures|Want to %{feature_title} for free?"), feature_title: s_('RegistrationFeatures|use this feature')))
    expect(registration_features_prompt_subject).not_to have_link(s_('RegistrationFeatures|Registration Features Program'))
  end
end
