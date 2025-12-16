# frozen_string_literal: true

module StubCurrentOrganization
  def stub_current_organization(organization)
    allow(::Current).to receive(:organization).and_return(organization)
  end
end
