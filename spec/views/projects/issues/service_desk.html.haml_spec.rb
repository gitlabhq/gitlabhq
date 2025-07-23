# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/issues/service_desk.html.haml', feature_category: :service_desk do
  include RenderedHtml

  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- objects need to be persisted
  let_it_be(:project) { create(:project, :private, service_desk_enabled: true) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }
  let_it_be(:guest) { create(:user, guest_of: project) }
  # rubocop:enable RSpec/FactoryBot/AvoidCreate

  let(:current_user) { reporter }
  let(:page) { rendered_html }
  let(:service_desk_list) { page.find('.js-service-desk-list') }

  before do
    assign(:project, project)

    allow(view).to receive_messages(
      project_issues_list_data: {},
      current_user: current_user
    )
    allow(view).to receive(:can?).and_call_original

    allow(::ServiceDesk).to receive(:enabled?).with(project).and_return(true)
    allow(::ServiceDesk).to receive(:supported?).and_return(true)

    render
  end

  context 'when user has admin_issue permission' do
    it 'renders service desk email address data attribute' do
      expect(rendered).to have_css('.js-service-desk-list')

      expect(service_desk_list['data-service-desk-email-address']).to eq(::ServiceDesk::Emails.new(project).address)
      expect(service_desk_list['data-can-admin-issues']).to eq('true')
    end
  end

  context 'when user does not have admin_issue permission' do
    let(:current_user) { guest }

    it 'does not render service desk email address data attribute' do
      expect(rendered).to have_css('.js-service-desk-list')

      expect(service_desk_list['data-service-desk-email-address']).to be_nil
      expect(service_desk_list['data-can-admin-issues']).to eq('false')
    end
  end
end
