module ConfigurationHelper
  # Returns a list of models from hashes/arrays contained in +project_tree+
  def names_from_tree(project_tree)
    project_tree.map do |branch_or_model|
      branch_or_model =  branch_or_model.to_s if branch_or_model.is_a?(Symbol)

      branch_or_model.is_a?(String) ? branch_or_model : names_from_tree(branch_or_model)
    end
  end

  def relation_class_for_name(relation_name)
    relation_name = Gitlab::ImportExport::RelationFactory::OVERRIDES[relation_name.to_sym] || relation_name
    relation_name.to_s.classify.constantize
  end
end
