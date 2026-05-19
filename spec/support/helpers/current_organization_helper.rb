# frozen_string_literal: true

module StubCurrentOrganization
  def stub_current_organization(organization)
    # Preload isolation state: this mimics behaviour of Gitlab::Current::Organization class
    organization&.isolated?

    allow(::Current).to receive_messages(organization: organization, organization_assigned: true)
  end
end
