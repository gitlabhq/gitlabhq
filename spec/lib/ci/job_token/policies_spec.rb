# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::JobToken::Policies, feature_category: :secrets_management do
  describe '.all_policies' do
    it 'contains exactly the valid policies' do
      schema = 'app/validators/json_schemas/ci_job_token_policies.json'
      valid_policies = Gitlab::Json.parse(File.read(schema)).dig('items', 'enum')

      expect(valid_policies).to match_array(described_class.all_values)
    end
  end
end
