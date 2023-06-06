# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DropTmpIndexOauthAccessTokensOnIdWhereExpiresInNull, feature_category: :database do
  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(ActiveRecord::Base.connection.indexes('oauth_access_tokens').map(&:name))
          .to include(described_class::TMP_INDEX)
      }

      migration.after -> {
        expect(ActiveRecord::Base.connection.indexes('oauth_access_tokens').map(&:name))
          .not_to include(described_class::TMP_INDEX)
      }
    end
  end
end
