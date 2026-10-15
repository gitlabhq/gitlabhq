# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'profiles/preferences/show', feature_category: :user_profile do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create_default(:user) }

  before do
    assign(:user, user)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'tabs' do
    before do
      allow(view).to receive(:integration_views).and_return([])

      render
    end

    it 'renders the core tabs in order, with the first tab active' do
      tab_titles = Capybara.string(rendered).all('.gl-tabs-nav a[role="tab"]').map { |tab| tab.text.strip }
      expect(tab_titles.first(4)).to eq(%w[Appearance Behavior Editing Localization])

      expect(rendered).to have_css('a[role="tab"][href="#appearance"].active[aria-controls="appearance-pane"]',
        text: 'Appearance')
      expect(rendered).to have_css('a[role="tab"][href="#behavior"][aria-controls="behavior-pane"]',
        text: 'Behavior')
      expect(rendered).to have_css('a[role="tab"][href="#editing"][aria-controls="editing-pane"]', text: 'Editing')
      expect(rendered).to have_css('a[role="tab"][href="#localization"][aria-controls="localization-pane"]',
        text: 'Localization')

      expect(rendered).to have_css('.tab-content > .tab-pane', count: tab_titles.size, visible: :all)
      expect(rendered).to have_css('.tab-pane.active#appearance-pane')
      expect(rendered).to have_css('.tab-pane.active', count: 1)
    end

    it 'keeps every pane inside the preferences form' do
      page = Capybara.string(rendered)
      tab_count = page.all('.gl-tabs-nav a[role="tab"]').size

      expect(rendered).to have_css('form#profile-preferences-form .tab-pane', count: tab_count, visible: :all)
      expect(rendered).to have_css('form#profile-preferences-form #js-profile-preferences-app')
    end

    it 'does not render the integrations tab when there are no integrations' do
      expect(rendered).not_to have_css('a[role="tab"][href="#integrations"]')
    end
  end

  describe 'with the preferences_tabs feature flag disabled' do
    before do
      stub_feature_flags(preferences_tabs: false)
      allow(view).to receive(:integration_views).and_return([])

      render
    end

    it 'renders every section inside the form without tabs' do
      expect(rendered).not_to have_css('.gl-tabs-nav')
      expect(rendered).not_to have_css('.tab-pane', visible: :all)
      expect(rendered).to have_css('form#profile-preferences-form #color-mode')
      expect(rendered).to have_css('form#profile-preferences-form #default-views')
      expect(rendered).to have_css('form#profile-preferences-form #code')
      expect(rendered).to have_css('form#profile-preferences-form #time-preferences')
    end

    it 'keeps the section anchors of the untabbed page' do
      expect(rendered).to have_css('#appearance #color-mode')
      expect(rendered).to have_css('#behavior #enabled_following')
      expect(rendered).to have_css('#localization #time-preferences')
    end
  end

  describe 'integrations tab' do
    before do
      allow(view).to receive(:integration_views).and_return([{ name: 'sourcegraph' }])

      render
    end

    it 'renders the tab last, with the integrations mount point inside its pane' do
      expect(rendered).to have_css('.gl-tabs-nav li:last-child a[role="tab"][href="#integrations"]',
        text: s_('Preferences|Integrations'))

      mount_point = Capybara.string(rendered)
        .find('.tab-pane#integrations-pane #js-profile-preferences-integrations', visible: :all)
      expect(Gitlab::Json::SafeParser.parse(mount_point['data-integration-views']))
        .to eq([{ 'name' => 'sourcegraph' }])
    end
  end

  describe 'appearance' do
    before do
      render
    end

    it 'has ids for anchoring' do
      expect(rendered).to have_css('#appearance-pane #color-mode')
      expect(rendered).to have_css('#appearance-pane #application-theme')
      expect(rendered).to have_css('#appearance-pane #layout')
      expect(rendered).to have_css('#appearance-pane #syntax-highlighting-theme')
      expect(rendered).to have_css('#appearance-pane #diffs-colors')
    end

    it 'passes the color modes to the color mode selector and the footer app' do
      color_modes = Gitlab::ColorModes.available_modes.to_json

      expect(rendered).to have_css('#js-color-mode-selector') { |el| el['data-color-modes'] == color_modes }
      expect(rendered).to have_css('#js-profile-preferences-app') { |el| el['data-color-modes'] == color_modes }
    end
  end

  describe 'behavior' do
    before do
      render
    end

    it 'has ids for anchoring' do
      expect(rendered).to have_css('#behavior-pane #default-views', visible: :all)
      expect(rendered).to have_css('#behavior-pane #keyboard-shortcuts', visible: :all)
      expect(rendered).to have_css('#behavior-pane #diffs', visible: :all)
      expect(rendered).to have_css('#behavior-pane #enabled_following', visible: :all)
    end

    it 'has helpful homepage setup guidance' do
      expect(rendered).to have_selector('[data-label="Homepage"]', visible: :all)
      expect(rendered).to have_selector("[data-description=" \
                                        "'Choose what content you want to see by default on your homepage.']",
        visible: :all)
    end
  end

  describe 'editing' do
    before do
      render
    end

    it 'has ids for anchoring' do
      expect(rendered).to have_css('#editing-pane #text-editor', visible: :all)
      expect(rendered).to have_css('#editing-pane #markdown', visible: :all)
      expect(rendered).to have_css('#editing-pane #code', visible: :all)
    end

    it 'has option for Render whitespace characters in the Web IDE' do
      expect(rendered).to have_unchecked_field('Render whitespace characters in the Web IDE', visible: :all)
    end
  end

  describe 'localization' do
    before do
      render
    end

    it 'has ids for anchoring' do
      expect(rendered).to have_css('#localization-pane #language-and-region', visible: :all)
      expect(rendered).to have_css('#localization-pane #time-preferences', visible: :all)
    end
  end
end
