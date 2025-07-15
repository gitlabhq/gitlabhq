# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe RemoveNotNullIntegrationsConstraint, feature_category: :integrations do
  include Database::TableSchemaHelpers

  describe '#up' do
    before do
      ApplicationRecord
        .connection
        .execute(
          'ALTER TABLE integrations ADD CONSTRAINT check_2aae034509 ' \
            'CHECK ((num_nonnulls(group_id, organization_id, project_id) = 1)) NOT VALID;'
        )
    end

    it 'removes the check constraint' do
      expect(check_constraint_definition(:integrations, 'check_2aae034509'))
        .to eq('CHECK ((num_nonnulls(group_id, organization_id, project_id) = 1)) NOT VALID')

      migrate!

      expect(check_constraint_definition(:integrations, 'check_2aae034509')).to be_nil
    end
  end
end
