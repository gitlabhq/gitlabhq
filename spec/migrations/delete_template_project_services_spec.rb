# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteTemplateProjectServices, :migration do
  let(:services) { table(:services) }
  let(:project) { table(:projects).create!(namespace_id: 1) }

  before do
    services.create!(template: true, project_id: project.id)
    services.create!(template: true)
    services.create!(template: false, project_id: project.id)
  end

  it 'deletes services when template and attached to a project' do
    expect { migrate! }.to change { services.where(template: true, project_id: project.id).count }.from(1).to(0)
      .and not_change { services.where(template: true, project_id: nil).count }
      .and not_change { services.where(template: false).where.not(project_id: nil).count }
  end
end
