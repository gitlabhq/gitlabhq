# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/settings/_two_factor_auth.html.haml', feature_category: :system_access do
  describe 'Top-level-group 2FA Settings' do
    let(:top_level_group) { build_stubbed(:group) }
    let(:user) { build_stubbed(:admin) }
    let(:form) { instance_double(Gitlab::FormBuilders::GitlabUiFormBuilder) }

    before do
      allow(view).to receive_messages(
        group: top_level_group,
        current_user: user,
        f: form
      )

      allow(form).to receive(:gitlab_ui_checkbox_component) do |_field, label, options = {}|
        "#{label} #{options[:help_text]}".html_safe # rubocop:disable Rails/OutputSafety -- Tests form rendering
      end

      allow(form).to receive_messages(
        label: '',
        text_field: ''
      )
    end

    context 'with :allow_mfa_for_subgroups setting' do
      it 'renders the checkbox' do
        render

        expect(rendered).to have_content('Allow more restrictive 2FA enforcement for subgroups')
        expect(rendered).to have_link(href: help_page_path('security/two_factor_authentication.md',
          anchor: '2fa-in-subgroups'))
      end
    end
  end
end
