# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_eks' do
  let_it_be(:admin) { create(:admin) }

  let(:page) { Capybara::Node::Simple.new(rendered) }

  before do
    assign(:application_setting, application_setting)
    allow(view).to receive(:current_user) { admin }
    allow(view).to receive(:expanded) { true }
  end

  shared_examples 'EKS secret access key input' do
    it 'renders an empty password field' do
      render
      expect(rendered).to have_field('Secret access key', type: 'password')
      expect(page.find_field('Secret access key').value).to be_blank
    end
  end

  context 'when eks_secret_access_key is not set' do
    let(:application_setting) { build(:application_setting) }

    include_examples 'EKS secret access key input'
  end

  context 'when eks_secret_access_key is set' do
    let(:application_setting) { build(:application_setting, eks_secret_access_key: 'eks_secret_access_key') }

    include_examples 'EKS secret access key input'
  end
end
