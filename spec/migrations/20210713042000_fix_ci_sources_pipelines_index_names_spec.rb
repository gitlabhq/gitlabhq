# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixCiSourcesPipelinesIndexNames, :migration, feature_category: :continuous_integration do
  def validate_foreign_keys_and_index!
    aggregate_failures do
      expect(subject.foreign_key_exists?(:ci_sources_pipelines, :ci_builds, column: :source_job_id, name: 'fk_be5624bf37')).to be_truthy
      expect(subject.foreign_key_exists?(:ci_sources_pipelines, :ci_pipelines, column: :pipeline_id, name: 'fk_e1bad85861')).to be_truthy
      expect(subject.foreign_key_exists?(:ci_sources_pipelines, :ci_pipelines, column: :source_pipeline_id, name: 'fk_d4e29af7d7')).to be_truthy
      expect(subject.foreign_key_exists?(:ci_sources_pipelines, :projects, column: :source_project_id, name: 'fk_acd9737679')).to be_truthy
      expect(subject.foreign_key_exists?(:ci_sources_pipelines, :projects, name: 'fk_1e53c97c0a')).to be_truthy
      expect(subject.foreign_key_exists?(:ci_sources_pipelines, :ci_builds, column: :source_job_id_convert_to_bigint, name: 'fk_be5624bf37_tmp')).to be_falsey

      expect(subject.index_exists_by_name?(:ci_sources_pipelines, described_class::NEW_INDEX_NAME)).to be_truthy
      expect(subject.index_exists_by_name?(:ci_sources_pipelines, described_class::OLD_INDEX_NAME)).to be_falsey
    end
  end

  it 'existing foreign keys and indexes are untouched' do
    validate_foreign_keys_and_index!

    migrate!

    validate_foreign_keys_and_index!
  end

  context 'with a legacy (pre-GitLab 10.0) foreign key' do
    let(:old_foreign_keys) { described_class::OLD_TO_NEW_FOREIGN_KEY_DEFS.keys }
    let(:new_foreign_keys) { described_class::OLD_TO_NEW_FOREIGN_KEY_DEFS.values.map { |entry| entry[:name] } }

    before do
      new_foreign_keys.each { |name| subject.remove_foreign_key_if_exists(:ci_sources_pipelines, name: name) }

      # GitLab 9.5.4: https://gitlab.com/gitlab-org/gitlab/-/blob/v9.5.4-ee/db/schema.rb#L2026-2030
      subject.add_foreign_key(:ci_sources_pipelines, :ci_builds, column: :source_job_id, name: 'fk_3f0c88d7dc', on_delete: :cascade)
      subject.add_foreign_key(:ci_sources_pipelines, :ci_pipelines, column: :pipeline_id, name: "fk_b8c0fac459", on_delete: :cascade)
      subject.add_foreign_key(:ci_sources_pipelines, :ci_pipelines, column: :source_pipeline_id, name: "fk_3a3e3cb83a", on_delete: :cascade)
      subject.add_foreign_key(:ci_sources_pipelines, :projects, column: :source_project_id, name: "fk_8868d0f3e4", on_delete: :cascade)
      subject.add_foreign_key(:ci_sources_pipelines, :projects, name: "fk_83b4346e48", on_delete: :cascade)

      # https://gitlab.com/gitlab-org/gitlab/-/blob/v9.5.4-ee/db/schema.rb#L443
      subject.add_index "ci_sources_pipelines", ["source_job_id"], name: described_class::OLD_INDEX_NAME, using: :btree
    end

    context 'when new index already exists' do
      it 'corrects foreign key constraints and drops old index' do
        expect { migrate! }.to change { subject.foreign_key_exists?(:ci_sources_pipelines, :ci_builds, column: :source_job_id, name: 'fk_3f0c88d7dc') }.from(true).to(false)

        validate_foreign_keys_and_index!
      end
    end

    context 'when new index does not exist' do
      before do
        subject.remove_index("ci_sources_pipelines", name: described_class::NEW_INDEX_NAME)
      end

      it 'drops the old index' do
        expect { migrate! }.to change { subject.index_exists_by_name?(:ci_sources_pipelines, described_class::OLD_INDEX_NAME) }.from(true).to(false)

        validate_foreign_keys_and_index!
      end
    end
  end
end
