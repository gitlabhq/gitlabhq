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

  context 'for pages multiple versions' do
    context 'when current user does not have access to pages multiple versions toggle' do
      it 'shows the multiple versions toggle' do
        allow(view)
          .to receive(:can?)
          .with(user, :pages_multiple_versions, project)
          .and_return(false)

        render

        expect(rendered).not_to have_content('Use multiple versions')
      end
    end

    context 'when current user have access to pages multiple versions toggle' do
      it 'shows the multiple versions toggle' do
        allow(view)
          .to receive(:can?)
          .with(user, :pages_multiple_versions, project)
          .and_return(true)

        render

        expect(rendered).to have_content('Use multiple deployments')
      end
    end
  end
end
