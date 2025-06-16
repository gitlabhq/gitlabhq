# frozen_string_literal: true

module StubCurrentOrganization
  def stub_current_organization(organization)
    allow_next_instance_of(Gitlab::Current::Organization) do |instance|
      allow(instance).to receive(:organization).and_return(organization)
    end
  end
end
