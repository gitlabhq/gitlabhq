# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::ShimoMenu do
  let_it_be_with_reload(:project) { create(:project) }

  let(:context) { Sidebars::Projects::Context.new(current_user: project.first_owner, container: project) }

  subject(:shimo_menu) { described_class.new(context) }

  describe '#render?' do
    context 'without a valid Shimo integration' do
      it "doesn't render the menu" do
        expect(shimo_menu.render?).to be_falsey
      end
    end

    context 'with a valid Shimo integration' do
      let_it_be_with_reload(:shimo_integration) { create(:shimo_integration, project: project) }

      context 'when integration is active' do
        it 'renders the menu' do
          expect(shimo_menu.render?).to eq true
        end

        it 'renders menu link' do
          expected_url = Rails.application.routes.url_helpers.project_integrations_shimo_path(project)
          expect(shimo_menu.link).to eq expected_url
        end
      end

      context 'when integration is inactive' do
        before do
          shimo_integration.update!(active: false)
        end

        it "doesn't render the menu" do
          expect(shimo_menu.render?).to eq false
        end
      end
    end
  end
end
