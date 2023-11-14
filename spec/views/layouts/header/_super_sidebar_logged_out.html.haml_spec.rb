# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/header/_super_sidebar_logged_out', feature_category: :navigation do
  before do
    allow(view).to receive(:current_user_mode).and_return(Gitlab::Auth::CurrentUserMode.new(nil))
  end

  context 'on gitlab.com' do
    before do
      allow(Gitlab).to receive(:com?).and_return(true)
      render
    end

    it 'renders marketing links' do
      expect(rendered).to have_content('Why GitLab')
      expect(rendered).to have_content('Pricing')
      expect(rendered).to have_content('Contact Sales')
    end

    it 'renders the free trial button' do
      expect(rendered).to have_content('Get free trial')
    end
  end

  context 'on self-managed' do
    it 'does not render marketing links' do
      render
      expect(rendered).not_to have_content('Why GitLab')
      expect(rendered).not_to have_content('Pricing')
      expect(rendered).not_to have_content('Contact Sales')
    end
  end

  it 'renders links to Explore and Sign-in and Register' do
    render
    expect(rendered).to have_content('Explore')
    expect(rendered).to have_content('Sign in')
    expect(rendered).to have_content('Register')
  end
end
