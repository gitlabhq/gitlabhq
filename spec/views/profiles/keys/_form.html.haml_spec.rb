# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'profiles/keys/_form.html.haml' do
  let_it_be(:key) { Key.new }

  let(:page) { Capybara::Node::Simple.new(rendered) }

  before do
    assign(:key, key)
  end

  context 'when the form partial is used' do
    before do
      allow(view).to receive(:ssh_key_expires_field_description).and_return('Key can still be used after expiration.')

      render
    end

    it 'renders the form with the correct action' do
      expect(page.find('form')['action']).to eq('/-/profile/keys')
    end

    it 'has the key field', :aggregate_failures do
      expect(rendered).to have_field('Key', type: 'textarea', placeholder: 'Typically starts with "ssh-ed25519 …" or "ssh-rsa …"')
      expect(rendered).to have_text("Paste your public SSH key, which is usually contained in the file '~/.ssh/id_ed25519.pub' or '~/.ssh/id_rsa.pub' and begins with 'ssh-ed25519' or 'ssh-rsa'. Do not paste your private SSH key, as that can compromise your identity.")
    end

    it 'has the title field', :aggregate_failures do
      expect(rendered).to have_field('Title', type: 'text', placeholder: 'e.g. My MacBook key')
      expect(rendered).to have_text('Give your individual key a title. This will be publicly visible.')
    end

    it 'has the expires at field', :aggregate_failures do
      expect(rendered).to have_field('Expires at', type: 'date')
      expect(page.find_field('Expires at')['min']).to eq(l(1.day.from_now, format: "%Y-%m-%d"))
      expect(rendered).to have_text('Key can still be used after expiration.')
    end

    it 'has the validation warning', :aggregate_failures do
      expect(rendered).to have_text("Oops, are you sure? Publicly visible private SSH keys can compromise your system.")
      expect(rendered).to have_button('Yes, add it')
    end

    it 'has the submit button' do
      expect(rendered).to have_button('Add key')
    end
  end
end
