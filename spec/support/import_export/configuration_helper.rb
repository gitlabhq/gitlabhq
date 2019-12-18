# frozen_string_literal: true

module ConfigurationHelper
  # Returns a list of models from hashes/arrays contained in +project_tree+
  def names_from_tree(project_tree)
    project_tree.map do |branch_or_model|
      branch_or_model =  branch_or_model.to_s if branch_or_model.is_a?(Symbol)

      branch_or_model.is_a?(String) ? branch_or_model : names_from_tree(branch_or_model)
    end
  end

  def all_relations(tree, tree_path = [])
    tree.flat_map do |relation_name, relations|
      relation_path = tree_path + [relation_name]
      [relation_path] + all_relations(relations, relation_path)
    end
  end

  def config_hash(config = Gitlab::ImportExport.config_file)
    Gitlab::ImportExport::Config.new(config: config).to_h
  end

  def relation_paths_for(key, config: Gitlab::ImportExport.config_file)
    # - project is not part of the tree, so it has to be added manually.
    all_relations({ project: config_hash(config).dig(:tree, key) })
  end

  def relation_names_for(key, config: Gitlab::ImportExport.config_file)
    names = names_from_tree(config_hash(config).dig(:tree, key))
    # Remove duplicated or add missing models
    # - project is not part of the tree, so it has to be added manually.
    # - milestone, labels, merge_request have both singular and plural versions in the tree, so remove the duplicates.
    # - User, Author... Models we do not care about for checking models
    names.flatten.uniq - %w(milestones labels user author merge_request design) + [key.to_s]
  end

  def relation_class_for_name(relation_name)
    relation_name = Gitlab::ImportExport::RelationFactory.overrides[relation_name.to_sym] || relation_name
    Gitlab::ImportExport::RelationFactory.relation_class(relation_name)
  end

  def parsed_attributes(relation_name, attributes, config: Gitlab::ImportExport.config_file)
    import_export_config = config_hash(config)
    excluded_attributes = import_export_config[:excluded_attributes][relation_name.to_sym]
    included_attributes = import_export_config[:included_attributes][relation_name.to_sym]
    attributes = attributes - JSON[excluded_attributes.to_json] if excluded_attributes
    attributes = attributes & JSON[included_attributes.to_json] if included_attributes

    attributes
  end

  def prohibited_key?(key)
    key =~ Gitlab::ImportExport::AttributeCleaner::PROHIBITED_REFERENCES && !permitted_key?(key)
  end

  def permitted_key?(key)
    Gitlab::ImportExport::AttributeCleaner::ALLOWED_REFERENCES.include?(key)
  end

  def associations_for(safe_model)
    safe_model.reflect_on_all_associations.map { |assoc| assoc.name.to_s }
  end
end
