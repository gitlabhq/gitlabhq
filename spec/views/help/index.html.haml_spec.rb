# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'help/index' do
  include StubVersion

  describe 'version information' do
    before do
      stub_helpers
    end

    it 'is hidden from guests' do
      stub_user(nil)
      stub_version('8.0.2', 'abcdefg')

      render

      expect(rendered).not_to match '8.0.2'
      expect(rendered).not_to match 'abcdefg'
    end

    context 'when logged in' do
      before do
        stub_user
      end

      it 'shows a link to the tag to users' do
        stub_version('8.0.2', 'abcdefg')

        render

        expect(rendered).to match '8.0.2'
        expect(rendered).to have_link('8.0.2', href: Gitlab::Source.release_url)
      end

      it 'shows a link to the commit for pre-releases' do
        stub_version('8.0.2-pre', 'abcdefg')

        render

        expect(rendered).to match '8.0.2'
        expect(rendered).to have_link('abcdefg', href: Gitlab::Source.release_url)
      end
    end
  end

  describe 'instance configuration link' do
    it 'is visible to guests' do
      render

      expect(rendered).to have_link(nil, href: help_instance_configuration_url)
    end
  end

  describe 'Markdown rendering' do
    before do
      assign(:help_index, 'Welcome to [GitLab](https://about.gitlab.com/) Documentation.')
    end

    it 'renders Markdown' do
      render

      expect(rendered).to have_link('GitLab', href: 'https://about.gitlab.com/')
    end
  end

  def stub_user(user = double)
    allow(view).to receive(:user_signed_in?).and_return(user)
  end

  def stub_helpers
    allow(view).to receive(:markdown).and_return('')
    allow(view).to receive(:current_application_settings).and_return(Gitlab::CurrentSettings.current_application_settings)
  end
end
