# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'user_settings/ssh_keys/_form.html.haml', feature_category: :system_access do
  include RenderedHtml
  include SshKeysHelper

  let_it_be(:key) { Key.new }

  let(:page) { rendered_html }

  before do
    assign(:key, key)
  end

  context 'when the form partial is used' do
    before do
      render
    end

    it 'renders the form with the correct action' do
      expect(page.find('form')['action']).to eq('/-/user_settings/ssh_keys')
    end

    it 'has the key field', :aggregate_failures do
      expect(rendered).to have_field('Key', type: 'textarea')
      expect(rendered).to have_text(
        format(s_('Profiles|Begins with %{ssh_key_algorithms}.'), ssh_key_algorithms: ssh_key_allowed_algorithms))
    end

    it 'has the title field', :aggregate_failures do
      expect(rendered).to have_field('Title', type: 'text', placeholder: 'Example: MacBook key')
      expect(rendered).to have_text('Key titles are publicly visible.')
    end

    it 'has the usage type field', :aggregate_failures do
      expect(page).to have_select _('Usage type'),
        selected: 'Authentication & Signing', options: ['Authentication & Signing', 'Authentication', 'Signing']
    end

    it 'has the expires at field', :aggregate_failures do
      expect(rendered).to have_field('Expiration date', type: 'text')
      expect(page.find_field('Expiration date')['min']).to eq(l(1.day.from_now, format: "%Y-%m-%d"))
      expect(rendered).to have_text(
        s_('Profiles|Optional but recommended. If set, key becomes invalid on the specified date.'))
    end

    it 'has the validation warning', :aggregate_failures do
      expect(rendered).to have_text("Are you sure? Publicly visible private SSH keys can compromise your system.")
      expect(rendered).to have_button('Yes, add it')
    end

    it 'has the submit button' do
      expect(rendered).to have_button('Add key')
    end
  end
end
