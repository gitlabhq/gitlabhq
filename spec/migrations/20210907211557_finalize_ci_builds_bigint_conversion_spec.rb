# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeCiBuildsBigintConversion, :migration, schema: 20210907182359, feature_category: :continuous_integration do
  context 'with an unexpected FK fk_3f0c88d7dc' do
    it 'removes the FK and migrates successfully' do
      # Add the unexpected FK
      subject.add_foreign_key(:ci_sources_pipelines, :ci_builds, column: :source_job_id, name: 'fk_3f0c88d7dc')

      expect { migrate! }.to change { subject.foreign_key_exists?(:ci_sources_pipelines, :ci_builds, column: :source_job_id, name: 'fk_3f0c88d7dc') }.from(true).to(false)

      # Additional check: The actually expected FK should still exist
      expect(subject.foreign_key_exists?(:ci_sources_pipelines, :ci_builds, column: :source_job_id, name: 'fk_be5624bf37')).to be_truthy
    end
  end
end
