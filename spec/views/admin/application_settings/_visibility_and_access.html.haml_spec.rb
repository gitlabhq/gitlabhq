# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_visibility_and_access.html.haml', feature_category: :mcp_server do
  let_it_be(:admin) { build_stubbed(:admin) }
  let(:application_setting) { build(:application_setting) }

  before do
    assign(:application_setting, application_setting)
    allow(view).to receive(:current_user).and_return(admin)
  end

  describe 'MCP client access checkbox' do
    let(:checkbox_selector) { 'input[name="application_setting[mcp_server_enabled]"][type="checkbox"]' }

    context 'when the setting is available' do
      before do
        allow(view).to receive(:mcp_server_setting_available?).and_return(true)
      end

      it 'renders the MCP client access section' do
        render

        expect(rendered).to have_content('MCP client access')
        expect(rendered).to have_field('Allow connection to GitLab', type: 'checkbox')
      end

      context 'when mcp_server_enabled is true' do
        let(:application_setting) { build(:application_setting, mcp_server_enabled: true) }

        it 'renders the checkbox as checked' do
          render

          expect(rendered).to have_css("#{checkbox_selector}[checked]")
        end
      end

      context 'when mcp_server_enabled is false' do
        let(:application_setting) { build(:application_setting, mcp_server_enabled: false) }

        it 'renders the checkbox as unchecked' do
          render

          expect(rendered).not_to have_css("#{checkbox_selector}[checked]")
        end
      end
    end

    context 'when the setting is not available' do
      before do
        allow(view).to receive(:mcp_server_setting_available?).and_return(false)
      end

      it 'does not render the MCP client access section' do
        render

        expect(rendered).not_to have_content('MCP client access')
        expect(rendered).not_to have_css(checkbox_selector)
      end
    end
  end
end
