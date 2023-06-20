# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_ai_access.html.haml', feature_category: :code_suggestions do
  let_it_be(:admin) { build_stubbed(:admin) }
  let(:page) { Capybara::Node::Simple.new(rendered) }

  before do
    allow(::Gitlab).to receive(:org_or_com?).and_return(false) # Will not render partial for .com or .org
    assign(:application_setting, application_setting)
    allow(view).to receive(:current_user) { admin }
    allow(view).to receive(:expanded).and_return(true)
  end

  context 'when ai_access_token is not set' do
    let(:application_setting) { build(:application_setting) }

    it 'renders an empty password field' do
      render
      expect(rendered).to have_field('Personal access token', type: 'password')
      expect(page.find_field('Personal access token').value).to be_blank
    end
  end

  context 'when ai_access_token is set' do
    let(:application_setting) do
      build(:application_setting, ai_access_token: 'ai_access_token',
        instance_level_code_suggestions_enabled: true)
    end

    it 'renders masked password field' do
      render
      expect(rendered).to have_field('Enter new personal access token', type: 'password')
      expect(page.find_field('Enter new personal access token').value).to eq(ApplicationSettingMaskedAttrs::MASK)
    end
  end
end
