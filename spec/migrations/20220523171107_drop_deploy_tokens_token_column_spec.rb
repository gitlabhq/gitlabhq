# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DropDeployTokensTokenColumn, feature_category: :continuous_delivery do
  let(:deploy_tokens) { table(:deploy_tokens) }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(deploy_tokens.column_names).to include('token')
      }

      migration.after -> {
        deploy_tokens.reset_column_information

        expect(deploy_tokens.column_names).not_to include('token')
      }
    end
  end
end
