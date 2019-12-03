# frozen_string_literal: true

require 'spec_helper'

describe 'layouts/application' do
  let(:user) { create(:user) }

  before do
    allow(view).to receive(:current_application_settings).and_return(Gitlab::CurrentSettings.current_application_settings)
    allow(view).to receive(:experiment_enabled?).and_return(false)
    allow(view).to receive(:session).and_return({})
    allow(view).to receive(:user_signed_in?).and_return(true)
    allow(view).to receive(:current_user).and_return(user)
  end

  context 'body data elements for pageview context' do
    let(:body_data) do
      {
        body_data_page: 'projects:issues:show',
        body_data_page_type_id: '1',
        body_data_project_id: '2',
        body_data_namespace_id: '3'
      }
    end

    before do
      allow(view).to receive(:body_data).and_return(body_data)
      render
    end

    it 'includes the body element page' do
      expect(rendered).to include('data-page="projects:issues:show"')
    end

    it 'includes the body element page_type_id' do
      expect(rendered).to include('data-page-type-id="1"')
    end

    it 'includes the body element project_id' do
      expect(rendered).to include('data-project-id="2"')
    end

    it 'includes the body element namespace_id' do
      expect(rendered).to include('data-namespace-id="3"')
    end
  end
end
