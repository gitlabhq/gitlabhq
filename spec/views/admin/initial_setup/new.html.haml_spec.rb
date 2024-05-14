# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/initial_setup/new', feature_category: :system_access do
  let_it_be(:admin) { build_stubbed(:admin, username: 'root', password_automatically_set: true) }

  before do
    assign(:user, admin)
  end

  context 'on first render' do
    it 'renders form with appropriate fields' do
      render

      expect(rendered).to have_field('Email', type: 'email')
      expect(rendered).to have_field('Password', type: 'password')
      expect(rendered).to have_field('Password Confirmation', type: 'password')
    end
  end

  context 'when previous submission failed' do
    let(:result) { ServiceResponse.error(message: 'Not enough capybaras') }

    before do
      assign(:result, result)
    end

    it 'renders an errors alert component' do
      render

      expect(rendered).to have_content('Not enough capybaras')
    end
  end
end
