# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_jira_connect.html.haml', feature_category: :integrations do
  let_it_be(:admin) { create(:admin) }
  let(:application_setting) { build(:application_setting) }

  before do
    assign(:application_setting, application_setting)
    allow(view).to receive(:expanded).and_return(true)
  end

  it 'renders the application ID field' do
    render
    expect(rendered).to have_field('Jira Connect Application ID', type: 'text')
  end

  it 'renders the asymmetric jwt cdn url field' do
    render
    expect(rendered).to have_field('Jira Connect Proxy URL', type: 'text')
  end

  it 'renders the enable public key storage checkbox' do
    render
    expect(rendered).to have_field('Enable public key storage', type: 'checkbox')
  end
end
