# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddIndexToProjectsOnMarkedForDeletionAt, feature_category: :projects do
  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(ActiveRecord::Base.connection.indexes('projects').map(&:name)).not_to include('index_projects_not_aimed_for_deletion')
      }

      migration.after -> {
        expect(ActiveRecord::Base.connection.indexes('projects').map(&:name)).to include('index_projects_not_aimed_for_deletion')
      }
    end
  end
end
