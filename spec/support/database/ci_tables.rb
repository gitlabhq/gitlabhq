# frozen_string_literal: true

# This module stores the CI-related database tables which are
# going to be moved to a separate database.
module Database
  module CiTables
    def self.include?(name)
      ci_tables.include?(name)
    end

    def self.ci_tables
      @@ci_tables ||= Set.new.tap do |tables| # rubocop:disable Style/ClassVars
        tables.merge(Ci::ApplicationRecord.descendants.map(&:table_name).compact)

        # It was decided that taggings/tags are best placed with CI
        # https://gitlab.com/gitlab-org/gitlab/-/issues/333413
        tables.add('taggings')
        tables.add('tags')
      end
    end
  end
end
