# frozen_string_literal: true
require 'spec_helper'
require_migration!

RSpec.describe UpdatePagesOnboardingState, feature_category: :pages do
  let(:migration) { described_class.new }
  let!(:namespaces) { table(:namespaces) }
  let!(:projects) { table(:projects) }
  let!(:project_pages_metadata) { table(:project_pages_metadata) }

  let!(:namespace1) { namespaces.create!(name: 'foo', path: 'foo') }
  let!(:namespace2) { namespaces.create!(name: 'bar', path: 'bar') }
  let!(:project1) { projects.create!(namespace_id: namespace1.id) }
  let!(:project2) { projects.create!(namespace_id: namespace2.id) }
  let!(:pages_metadata1) do
    project_pages_metadata.create!(
      project_id: project1.id,
      deployed: true,
      onboarding_complete: false
    )
  end

  let!(:pages_metadata2) do
    project_pages_metadata.create!(
      project_id: project2.id,
      deployed: false,
      onboarding_complete: false
    )
  end

  describe '#up' do
    before do
      migration.up
    end

    it 'sets the onboarding_complete attribute to the value of deployed' do
      expect(pages_metadata1.reload.onboarding_complete).to eq(true)
      expect(pages_metadata2.reload.onboarding_complete).to eq(false)
    end
  end

  describe '#down' do
    before do
      migration.up
      migration.down
    end

    it 'sets all onboarding_complete attributes to false' do
      expect(pages_metadata1.reload.onboarding_complete).to eq(false)
      expect(pages_metadata2.reload.onboarding_complete).to eq(false)
    end
  end
end
