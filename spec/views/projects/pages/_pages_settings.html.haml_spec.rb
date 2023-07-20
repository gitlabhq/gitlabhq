# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/pages/_pages_settings', feature_category: :pages do
  let_it_be(:project) { build_stubbed(:project, :repository) }
  let_it_be(:user) { build_stubbed(:user) }

  before do
    assign(:project, project)
    allow(view).to receive(:current_user).and_return(user)
  end

  context 'for pages unique domain' do
    it 'shows the unique domain toggle' do
      render

      expect(rendered).to have_content('Use unique domain')
    end

    context 'when pages_unique_domain feature flag is disabled' do
      it 'does not show the unique domain toggle' do
        stub_feature_flags(pages_unique_domain: false)

        # We have to use `view.render` because `render` causes issues
        # https://github.com/rails/rails/issues/41320
        expect(view.render('projects/pages/pages_settings')).to be_nil
      end
    end
  end
end
