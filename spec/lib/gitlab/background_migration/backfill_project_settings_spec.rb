# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillProjectSettings, schema: 20200114113341 do
  let(:projects) { table(:projects) }
  let(:project_settings) { table(:project_settings) }
  let(:namespace) { table(:namespaces).create!(name: 'user', path: 'user') }
  let(:project) { projects.create!(namespace_id: namespace.id) }

  subject { described_class.new }

  describe '#perform' do
    it 'creates settings for all projects in range' do
      projects.create!(id: 5, namespace_id: namespace.id)
      projects.create!(id: 7, namespace_id: namespace.id)
      projects.create!(id: 8, namespace_id: namespace.id)

      subject.perform(5, 7)

      expect(project_settings.all.pluck(:project_id)).to contain_exactly(5, 7)
    end
  end
end
