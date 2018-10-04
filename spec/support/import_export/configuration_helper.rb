module ConfigurationHelper
  # Returns a list of models from hashes/arrays contained in +project_tree+
  def names_from_tree(project_tree)
    project_tree.map do |branch_or_model|
      branch_or_model =  branch_or_model.to_s if branch_or_model.is_a?(Symbol)

      branch_or_model.is_a?(String) ? branch_or_model : names_from_tree(branch_or_model)
    end
  end

  def relation_class_for_name(relation_name)
    relation_name = Gitlab::ImportExport::RelationFactory.overrides[relation_name.to_sym] || relation_name
    Gitlab::ImportExport::RelationFactory.relation_class(relation_name)
  end

  def parsed_attributes(relation_name, attributes)
    excluded_attributes = config_hash['excluded_attributes'][relation_name]
    included_attributes = config_hash['included_attributes'][relation_name]

    attributes = attributes - JSON[excluded_attributes.to_json] if excluded_attributes
    attributes = attributes & JSON[included_attributes.to_json] if included_attributes

    attributes
  end

  def associations_for(safe_model)
    safe_model.reflect_on_all_associations.map { |assoc| assoc.name.to_s }
  end
end
