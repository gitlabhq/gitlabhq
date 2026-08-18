# frozen_string_literal: true

require 'spec_helper'

# A table whose sharding key is carried through a parent must not reference the
# sharding root with a *stronger* foreign key than its parent does. In particular,
# when the parent reaches the root via a loose foreign key (which deliberately
# tolerates orphaned rows until an async cleanup runs), the child must not add a
# hard database foreign key to the same root: the hard FK rejects the orphaned
# sharding key values the parent still holds, which aborted a production upgrade.
#
# See https://gitlab.com/gitlab-org/gitlab/-/work_items/606453 and INC-12001.
RSpec.describe 'sharding key foreign key strength', feature_category: :cell do
  # The recognised sharding-key reference tables.
  sharding_roots = %w[projects namespaces organizations users].freeze

  # Pre-existing violations tracked by https://gitlab.com/gitlab-org/gitlab/-/work_items/606453.
  # Each entry is a `<child_table>.<sharding_key_column>` whose hard FK to the sharding root
  # is stronger than the parent's loose FK. Remove an entry once the child's direct FK is
  # dropped (relying on the parent chain) or aligned with the parent's mechanism.
  # DO NOT add new entries: the generator must not emit a hard FK when the parent carries the key.
  allowed_hard_fk_stronger_than_parent = [
    'packages_helm_metadata_cache_states.project_id',
    'snippet_repositories.snippet_organization_id',
    'snippet_repository_storage_moves.snippet_organization_id',
    'snippet_statistics.snippet_organization_id',
    'snippet_user_mentions.snippet_organization_id'
  ].freeze

  let_it_be(:offenders) { hard_over_loose_offenders(sharding_roots) }
  let(:offending_keys) { offenders.keys }

  it 'does not add a child FK to the sharding root stronger than its parent' do
    new_violations = offending_keys - allowed_hard_fk_stronger_than_parent

    expect(new_violations).to be_empty, <<~ERROR
      The following tables inherit their sharding key from a parent that references the
      sharding root via a loose foreign key, but add a stronger hard foreign key to the
      root themselves:

      #{new_violations.map { |k| "  - #{offenders[k]}" }.join("\n")}

      A hard FK on the child rejects the orphaned sharding key values the parent's loose
      FK deliberately tolerates, which can abort migrations and upgrades (INC-12001).
      Do not add a direct FK to the sharding root when the parent carries the key: rely on
      the child -> parent cascade FK plus the parent's loose FK, or mirror the parent's loose FK.
      See https://gitlab.com/gitlab-org/gitlab/-/work_items/606453.
    ERROR
  end

  it 'has no stale entries in the allowlist' do
    stale_allowlist = allowed_hard_fk_stronger_than_parent - offending_keys

    expect(stale_allowlist).to be_empty, <<~ERROR
      The following entries no longer violate the invariant (the child no longer has a hard
      FK stronger than its parent) and must be removed from `allowed_hard_fk_stronger_than_parent`:

      #{stale_allowlist.map { |k| "  - #{k}" }.join("\n")}
    ERROR
  end

  private

  # Returns a hash of `<child>.<column>` => human-readable description for every
  # finalized sharding key whose hard FK to a sharding root is stronger than the
  # loose FK its key-carrying parent uses to reach the same root.
  def hard_over_loose_offenders(roots)
    offenders = {}

    Gitlab::Database::Dictionary.entries.each do |entry|
      sharding_key = entry.sharding_key
      next if sharding_key.blank?

      base_models = Gitlab::Database.schemas_to_base_models[entry.gitlab_schema]
      next if base_models.blank?

      child = entry.table_name

      # A hard FK can only exist within a single database, so the child's outgoing
      # FKs (and therefore its parents) are all reachable on the child's connection.
      Gitlab::Database::SharedModel.using_connection(base_models.first.connection) do
        next if Gitlab::Database::PostgresPartition.partition_exists?(child)

        sharding_key.each do |column, root|
          next unless roots.include?(root)

          child_fk = hard_fk(child, column, root)
          next unless child_fk # no hard FK on the child -> it cannot be stronger

          key_carrying_parent = find_loose_only_parent(child, root)
          next unless key_carrying_parent

          offenders["#{child}.#{column}"] =
            "#{child}.#{column} -> #{root} (hard ON DELETE #{child_fk.on_delete_action}) " \
              "but parent #{key_carrying_parent} -> #{root} is a loose FK only"
        end
      end
    end

    offenders
  end

  # Finds a parent of `child` (reachable via an outgoing hard FK) that carries a
  # sharding key referencing `root` only through a loose FK (no hard FK).
  def find_loose_only_parent(child, root)
    Gitlab::Database::PostgresForeignKey.by_constrained_table_name(child).each do |fk|
      parent = fk.referenced_table_name
      next if parent == root

      parent_entry = Gitlab::Database::Dictionary.entries.find_by_table_name(parent)
      next if parent_entry.nil?

      parent_key_columns = (parent_entry.sharding_key || {}).select { |_, r| r == root }.keys
      next if parent_key_columns.empty?

      parent_has_hard_fk = parent_key_columns.any? { |col| hard_fk(parent, col, root) }
      next if parent_has_hard_fk

      parent_has_loose_fk = parent_key_columns.any? { |col| loose_fk?(parent, col, root) }
      return parent if parent_has_loose_fk
    end

    nil
  end

  def hard_fk(from_table, column, to_table)
    Gitlab::Database::PostgresForeignKey
      .by_constrained_table_name(from_table)
      .by_referenced_table_name(to_table)
      .by_constrained_columns(column)
      .first
  end

  def loose_fk?(from_table, column, to_table)
    Gitlab::Database::LooseForeignKeys.definitions.any? do |definition|
      definition.from_table == from_table &&
        definition.to_table == to_table &&
        definition.options[:column].to_s == column.to_s
    end
  end
end
