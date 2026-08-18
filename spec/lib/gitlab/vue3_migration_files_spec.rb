# frozen_string_literal: true

require 'fast_spec_helper'
require 'yaml'
require_relative '../../../lib/gitlab/vue3_migration'

# Validates the `vue3_migration.yml` files that opt a page index.js entrypoint
# into the Vue 3 migration. The schema is documented in `config/helpers/vue3_migration_file_validation.js`.
#
# Pages without a `vue3_migration.yml` file are treated as Vue 2 only.
# The yml file must always sit next to a `index.js` entrypoint.
RSpec.describe 'vue3_migration.yml - vue 3 migration config verification', feature_category: :tooling do
  root = File.expand_path('../../..', __dir__)
  migration_filename = Gitlab::Vue3Migration::VUE3_MIGRATION_FILENAME
  allowed_statuses = Gitlab::Vue3Migration::VUE3_MIGRATION_ALLOWED_STATUSES
  allowed_keys = Gitlab::Vue3Migration::VUE3_MIGRATION_ALLOWED_KEYS

  pages_glob = Gitlab::Vue3Migration::VUE3_MIGRATION_PAGES_GLOB
  feature_flags_glob = '{,ee/,jh/}config/feature_flags/**/*.yml'

  # --------------------------------------------------------------------------
  # Helpers
  # --------------------------------------------------------------------------

  # Repo-relative path for display in failure messages.
  relative_to_root = ->(absolute) { absolute.delete_prefix("#{root}/") }

  # Position of an `index.js` relative to its page root, used to detect
  # overrides across CE/EE/JH and to produce a stable label for spec contexts.
  index_subpath = ->(index_file) {
    index_file.match(%r{app/assets/javascripts/pages/(.+)/index\.js\z})[1]
  }

  # --------------------------------------------------------------------------
  # File discovery
  # --------------------------------------------------------------------------

  # All `vue3_migration.yml` files across editions
  migration_files = Dir.glob(File.join(root, "#{pages_glob}/**/#{migration_filename}"))

  # All `index.js` entrypoints across editions
  index_files = Dir.glob(File.join(root, "#{pages_glob}/**/index.js"))

  # Group every `index.js` by its position relative to its page root, so
  # overridden entrypoints (same path under CE/EE/JH) collapse to the same
  # key. Only overridden entrypoints (size > 1) need cross-edition checks.
  overridden_indexes = index_files.group_by(&index_subpath).select { |_, files| files.size > 1 }

  # Known feature flags, used to validate `feature_flag` references.
  feature_flag_names = Dir.glob(File.join(root, feature_flags_glob))
                          .map { |path| File.basename(path, '.yml') }
                          .to_set

  describe 'file presence' do
    it "does not have orphan #{migration_filename} files (must have sibling index.js)" do
      orphans = migration_files.reject do |meta_file|
        File.exist?(File.join(File.dirname(meta_file), 'index.js'))
      end

      relative_orphans = orphans.map(&relative_to_root)

      expect(relative_orphans).to be_empty,
        "Orphan #{migration_filename} files (no sibling index.js):\n  #{relative_orphans.join("\n  ")}"
    end
  end

  describe 'file schema' do
    migration_files.each do |meta_file|
      context relative_to_root.call(meta_file) do
        let(:doc) { YAML.safe_load_file(meta_file) }

        it 'is a YAML mapping' do
          expect(doc).to be_a(Hash), "expected a mapping, got #{doc.class}"
        end

        it 'has only allowed keys' do
          unknown = doc.keys - allowed_keys
          expect(unknown).to be_empty,
            "unknown key(s): #{unknown.join(', ')}. Allowed: #{allowed_keys.join(', ')}."
        end

        it 'has a valid status' do
          expect(doc['status']).to be_a(String), '`status` is required and must be a string'
          expect(allowed_statuses).to include(doc['status']),
            "`status` must be one of #{allowed_statuses.inspect} (got #{doc['status'].inspect})"
        end

        it 'declares feature_flag iff status is rollout' do
          status = doc['status']
          flag = doc['feature_flag']

          if status == 'rollout'
            expect(flag).to be_a(String), '`feature_flag` is required when status is `rollout`'
            expect(flag).not_to be_empty, '`feature_flag` must not be empty'
          else
            expect(flag).to be_nil, "`feature_flag` must be absent when status is `#{status}`"
          end
        end

        it 'references a feature flag that exists under config/feature_flags' do
          flag = doc['feature_flag']
          next if flag.nil?

          expect(feature_flag_names).to include(flag),
            "feature flag `#{flag}` is not defined under config/feature_flags/**/*.yml"
        end
      end
    end
  end

  # If `index.js` files are overridden across editions (CE vs EE / JH),
  # the corresponding `vue3_migration.yml` files must all be present and identical.
  # Otherwise a FOSS build and an EE build would resolve the same page to different
  # migration states.
  describe 'consistency across overridden index.js entrypoints' do
    overridden_indexes.each do |relative_dir, indexes|
      context "for overridden index.js entrypoint pages/#{relative_dir.tr('/', '.')}" do
        # Pair each overridden index.js with its sibling YAML, if any.
        yaml_paths = indexes.map do |idx|
          candidate = File.join(File.dirname(idx), migration_filename)
          File.exist?(candidate) ? candidate : nil
        end

        present_yamls = yaml_paths.compact

        # No metadata anywhere - the entrypoint is Vue 2 only, nothing to check.
        next if present_yamls.empty?

        it "has a #{migration_filename} next to every overridden index.js" do
          missing = indexes.zip(yaml_paths).filter_map do |idx, yml|
            relative_to_root.call(idx) if yml.nil?
          end

          expect(missing).to be_empty,
            "Overridden CE/EE/JH index.js entrypoints must all declare #{migration_filename}, " \
              "missing next to:\n  #{missing.join("\n  ")}"
        end

        next unless present_yamls.size > 1

        it 'is identical across every overridden index.js entrypoint' do
          docs = present_yamls.map { |f| [f, YAML.safe_load_file(f)] }
          unique_docs = docs.map { |_, d| d }.uniq

          disagreement = docs.map do |path, d|
            "  #{relative_to_root.call(path)}: #{d.inspect}"
          end.join("\n")

          expect(unique_docs.size).to eq(1),
            "#{migration_filename} files disagree across overridden index.js entrypoints:\n#{disagreement}"
        end
      end
    end
  end
end
