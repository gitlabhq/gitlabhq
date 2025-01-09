# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/pages/_pages_settings', feature_category: :pages do
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:user) { build_stubbed(:user) }

  before do
    stub_config(pages: {
      enabled: true,
      external_http: true,
      external_https: true,
      access_control: false
    })
    assign(:project, project)
    allow(view).to receive(:current_user).and_return(user)
  end

  context 'for pages unique domain' do
    it 'shows the unique domain toggle' do
      render

      expect(rendered).to have_content('Use unique domain')
    end
  end

  context 'when pages_domains is empty' do
    before do
      allow(project).to receive(:pages_domains).and_return([])
    end

    it 'does not render the redirect domains section' do
      render

      expect(rendered).not_to have_selector('.form-group', text: 'Primary domain')
    end
  end

  context 'when pages_domains is not empty' do
    before do
      allow(project).to receive(:pages_domains).and_return([build_stubbed(:pages_domain)])
      allow(view).to receive(:project_pages_domain_choices).and_return(
        options_for_select([['new.domain.com', 'new.domain.com']])
      )
    end

    it 'renders the redirect domains section' do
      render

      expect(rendered).to have_content('Primary domain')
    end
  end
end
