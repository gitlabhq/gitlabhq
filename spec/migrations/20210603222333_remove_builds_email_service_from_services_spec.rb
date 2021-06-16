# frozen_string_literal: true

require 'spec_helper'

require_migration!('remove_builds_email_service_from_services')

RSpec.describe RemoveBuildsEmailServiceFromServices do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:services) { table(:services) }
  let(:namespace) { namespaces.create!(name: 'foo', path: 'bar') }
  let(:project) { projects.create!(namespace_id: namespace.id) }

  it 'correctly deletes `BuildsEmailService` services' do
    services.create!(project_id: project.id, type: 'BuildsEmailService')
    services.create!(project_id: project.id, type: 'OtherService')

    expect(services.all.pluck(:type)).to match_array %w[BuildsEmailService OtherService]

    migrate!

    expect(services.all.pluck(:type)).to eq %w[OtherService]
  end
end
