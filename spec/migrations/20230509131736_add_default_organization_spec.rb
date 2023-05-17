# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe AddDefaultOrganization, feature_category: :cell do
  let(:organization) { table(:organizations) }

  it "correctly migrates up and down" do
    reversible_migration do |migration|
      migration.before -> {
        expect(organization.where(id: 1, name: 'Default')).to be_empty
      }
      migration.after -> {
        expect(organization.where(id: 1, name: 'Default')).not_to be_empty
      }
    end
  end
end
