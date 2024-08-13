# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/identities/index.html.haml', :aggregate_failures do
  include Admin::IdentitiesHelper

  let_it_be(:ldap_user) { create(:omniauth_user, provider: 'ldapmain', extern_uid: 'ldap-uid') }

  before do
    assign(:user, ldap_user)
    view.lookup_context.prefixes = ['admin/identities']
  end

  context 'without identities' do
    before do
      assign(:identities, [])
    end

    it 'shows empty state' do
      render

      expect(rendered).to include('data-testid="identities-empty-state"')
      expect(rendered).to include(_('This user has no identities'))
    end
  end

  context 'with LDAP identities' do
    before do
      assign(:identities, ldap_user.identities)
    end

    it 'shows exactly 6 columns' do
      render

      expect(rendered).to include('</td>').exactly(6)
    end

    it 'shows identity without provider ID or group' do
      render

      # Provider
      expect(rendered).to include('ldap (ldapmain)')
      # Provider ID
      expect(rendered).to include('data-testid="provider_id_blank"')
      # Group
      expect(rendered).to include('data-testid="saml_group_blank"')
      # Identifier
      expect(rendered).to include('ldap-uid')
    end

    it 'shows edit and delete identity buttons' do
      render

      expect(rendered).to include("aria-label=\"#{_('Edit')}\"")
      expect(rendered).to include("aria-label=\"#{_('Delete identity')}\"")
    end
  end
end
