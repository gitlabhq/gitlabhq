# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe EnsureDefaultOrganization, feature_category: :cell do
  let(:organization) { table(:organizations) }

  it "creates default organization if needed" do
    reversible_migration do |migration|
      migration.before -> {
        expect(organization.where(id: 1, name: 'Default', path: 'default')).to be_empty
      }
      migration.after -> {
        expect(organization.where(id: 1, name: 'Default', path: 'default')).not_to be_empty
      }
    end
  end

  context 'when default organization already exists' do
    it "does not creates default organization if needed" do
      reversible_migration do |migration|
        migration.before -> {
          organization.create!(id: 1, name: 'Default', path: 'default')

          expect(organization.where(id: 1, name: 'Default', path: 'default')).not_to be_empty
        }
        migration.after -> {
          expect(organization.where(id: 1, name: 'Default', path: 'default')).not_to be_empty
        }
      end
    end
  end

  context 'when the path is in use by another organization' do
    before do
      organization.create!(id: 1000, name: 'Default', path: 'default')
    end

    it "adds a random hash to the path" do
      reversible_migration do |migration|
        migration.after -> {
          default_organization = organization.where(id: 1)

          expect(default_organization.first.path).to match(/default-\w{6}/)
        }
      end
    end
  end
end
