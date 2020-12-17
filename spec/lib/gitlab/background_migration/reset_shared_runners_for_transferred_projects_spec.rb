# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::ResetSharedRunnersForTransferredProjects, schema: 20201110161542 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }

  let(:namespace_1) { namespaces.create!(name: 'foo', path: 'foo', shared_runners_enabled: true, allow_descendants_override_disabled_shared_runners: false ) }
  let(:namespace_2) { namespaces.create!(name: 'foo', path: 'foo', shared_runners_enabled: false, allow_descendants_override_disabled_shared_runners: false ) }
  let(:namespace_3) { namespaces.create!(name: 'bar', path: 'bar', shared_runners_enabled: false, allow_descendants_override_disabled_shared_runners: true ) }
  let(:project_1_1) { projects.create!(namespace_id: namespace_1.id, shared_runners_enabled: true) }
  let(:project_1_2) { projects.create!(namespace_id: namespace_1.id, shared_runners_enabled: false) }
  let(:project_2_1) { projects.create!(namespace_id: namespace_2.id, shared_runners_enabled: true) }
  let(:project_2_2) { projects.create!(namespace_id: namespace_2.id, shared_runners_enabled: false) }
  let(:project_3_1) { projects.create!(namespace_id: namespace_3.id, shared_runners_enabled: true) }
  let(:project_3_2) { projects.create!(namespace_id: namespace_3.id, shared_runners_enabled: false) }

  it 'corrects each project shared_runners_enabled column' do
    expect do
      described_class.new.perform(namespace_1.id, namespace_3.id)
      project_1_1.reload
      project_1_2.reload
      project_2_1.reload
      project_2_2.reload
      project_3_1.reload
      project_3_2.reload
    end.to not_change(project_1_1, :shared_runners_enabled).from(true)
    .and not_change(project_1_2, :shared_runners_enabled).from(false)
    .and change(project_2_1, :shared_runners_enabled).from(true).to(false)
    .and not_change(project_2_2, :shared_runners_enabled).from(false)
    .and not_change(project_3_1, :shared_runners_enabled).from(true)
    .and not_change(project_3_2, :shared_runners_enabled).from(false)
  end
end
