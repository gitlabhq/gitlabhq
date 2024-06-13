# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devise/shared/_footer', feature_category: :system_access do
  subject { render && rendered }

  context 'when public visibility is restricted' do
    before do
      allow(view).to receive(:public_visibility_restricted?).and_return(true)
    end

    it { is_expected.not_to have_link(_('Explore'), href: explore_root_path) }
    it { is_expected.not_to have_link(_('Help'), href: help_path) }
  end

  context 'when public visibility is not restricted' do
    before do
      allow(view).to receive(:public_visibility_restricted?).and_return(false)
    end

    it { is_expected.to have_link(_('Explore'), href: explore_root_path) }
    it { is_expected.to have_link(_('Help'), href: help_path) }
  end

  it { is_expected.to have_link(_('About GitLab'), href: ApplicationHelper.promo_url) }
  it { is_expected.to have_link(_('Community forum'), href: ApplicationHelper.community_forum) }

  context 'when one trust is enabled' do
    before do
      allow(view).to receive(:one_trust_enabled?).and_return(true)
    end

    it { is_expected.to have_button(_('Cookie Preferences'), class: 'ot-sdk-show-settings') }
  end

  context 'when one trust is disabled' do
    before do
      allow(view).to receive(:one_trust_enabled?).and_return(false)
    end

    it { is_expected.not_to have_button(_('Cookie Preferences'), class: 'ot-sdk-show-settings') }
  end

  context 'with disable_preferred_language_cookie feature flag disabled (default)' do
    before do
      stub_feature_flags(disable_preferred_language_cookie: false)
    end

    it { is_expected.to have_css('.js-language-switcher') }
  end

  context 'with disable_preferred_language_cookie feature flag enabled' do
    it { is_expected.not_to have_css('.js-language-switcher') }
  end
end
