# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'dashboard/projects/_blank_state_welcome.html.haml' do
  context 'with regular user' do
    context 'with project creation enabled' do
      let_it_be(:user) { create(:user) }

      before do
        allow(view).to receive(:current_user).and_return(user)
      end

      it 'has a doc_url' do
        render

        expect(rendered).to have_link(href: Gitlab::Saas.doc_url)
      end

      it "shows create project panel" do
        render

        expect(rendered).to include(_('Create a project'))
      end
    end

    context 'with project creation disabled' do
      let_it_be(:user_projects_limit) { create(:user, projects_limit: 0) }

      before do
        allow(view).to receive(:current_user).and_return(user_projects_limit)
      end

      it "doesn't show create project panel" do
        render

        expect(rendered).not_to include(_('Create a project'))
      end
    end
  end

  context 'with external user' do
    let_it_be(:external_user) { create(:user, :external) }

    before do
      allow(view).to receive(:current_user).and_return(external_user)
    end

    it "doesn't show create project panel" do
      render

      expect(rendered).not_to include(_('Create a project'))
    end
  end
end
