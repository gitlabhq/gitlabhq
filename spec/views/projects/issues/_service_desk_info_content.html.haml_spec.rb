# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/issues/service_desk/_service_desk_info_content' do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:service_desk_address) { 'address@example.com' }

  before do
    assign(:project, project)
    allow(project).to receive(:service_desk_address).and_return(service_desk_address)
    allow(view).to receive(:current_user).and_return(user)
  end

  context 'when service desk is disabled' do
    before do
      allow(project).to receive(:service_desk_enabled?).and_return(false)
    end

    context 'when the logged user is at least maintainer' do
      before do
        project.add_maintainer(user)
      end

      it 'shows the info including the project settings link', :aggregate_failures do
        render

        expect(rendered).to have_text('Use Service Desk')
        expect(rendered).not_to have_text(service_desk_address)
        expect(rendered).to have_link(href: "/#{project.full_path}/edit")
      end
    end

    context 'when the logged user is at only a developer' do
      before do
        project.add_developer(user)
      end

      it 'shows the info without the project settings link', :aggregate_failures do
        render

        expect(rendered).to have_text('Use Service Desk')
        expect(rendered).not_to have_text(service_desk_address)
        expect(rendered).not_to have_link(href: "/#{project.full_path}/edit")
      end
    end
  end

  context 'when service desk is enabled' do
    before do
      allow(project).to receive(:service_desk_enabled?).and_return(true)
    end

    context 'when the logged user is at least reporter' do
      before do
        project.add_reporter(user)
      end

      it 'shows the info including the email address', :aggregate_failures do
        render

        expect(rendered).to have_text('Use Service Desk')
        expect(rendered).to have_text(service_desk_address)
        expect(rendered).not_to have_link(href: "/#{project.full_path}/edit")
      end
    end

    context 'when the logged user is at only a guest' do
      before do
        project.add_guest(user)
      end

      it 'shows the info without the email address', :aggregate_failures do
        render

        expect(rendered).to have_text('Use Service Desk')
        expect(rendered).not_to have_text(service_desk_address)
        expect(rendered).not_to have_link(href: "/#{project.full_path}/edit")
      end
    end

    context 'when user is not logged in' do
      let(:user) { nil }

      it 'shows the info without the email address', :aggregate_failures do
        render

        expect(rendered).to have_text('Use Service Desk')
        expect(rendered).not_to have_text(service_desk_address)
        expect(rendered).not_to have_link(href: "/#{project.full_path}/edit")
      end
    end
  end
end
