# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Features do
  describe '.project_migration_enabled' do
    let_it_be(:top_level_namespace) { create(:group) }

    context 'when bulk_import_projects feature flag is enabled' do
      it 'returns true' do
        stub_feature_flags(bulk_import_projects: true)

        expect(described_class.project_migration_enabled?).to eq(true)
      end

      context 'when feature flag is enabled on root ancestor level' do
        it 'returns true' do
          stub_feature_flags(bulk_import_projects: top_level_namespace)

          expect(described_class.project_migration_enabled?(top_level_namespace.full_path)).to eq(true)
        end
      end

      context 'when feature flag is enabled on a different top level namespace' do
        it 'returns false' do
          stub_feature_flags(bulk_import_projects: top_level_namespace)

          different_namepace = create(:group)

          expect(described_class.project_migration_enabled?(different_namepace.full_path)).to eq(false)
        end
      end
    end

    context 'when bulk_import_projects feature flag is disabled' do
      it 'returns false' do
        stub_feature_flags(bulk_import_projects: false)

        expect(described_class.project_migration_enabled?(top_level_namespace.full_path)).to eq(false)
      end
    end
  end
end
