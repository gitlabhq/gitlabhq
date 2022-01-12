# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/header/_gitlab_version' do
  describe 'when show_version_check? is true' do
    before do
      allow(view).to receive(:show_version_check?).and_return(true)
      render
    end

    it 'renders the version check badge' do
      expect(rendered).to have_selector('.js-gitlab-version-check')
    end
  end
end
