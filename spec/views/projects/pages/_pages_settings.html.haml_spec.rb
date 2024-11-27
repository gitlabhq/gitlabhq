# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/pages/_pages_settings', feature_category: :pages do
  let_it_be(:project) { build_stubbed(:project) }
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
  end
end
