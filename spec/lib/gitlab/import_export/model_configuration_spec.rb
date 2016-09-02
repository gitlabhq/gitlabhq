require 'spec_helper'

# Part of the Import/Export feature security testing
# Finds if a new model has been added that can potentially be part of the Import/Export
# If it finds a new model, it will show a +failure_message+ with the options available.
describe 'Model configuration', lib: true do
  include ConfigurationHelper

  let(:config_hash) { YAML.load_file(Gitlab::ImportExport.config_file).deep_stringify_keys }
  let(:relation_names) do
    names = names_from_tree(config_hash['project_tree'])

    # Remove duplicated or add missing models
    # - project is not part of the tree, so it has to be added manually.
    # - milestone, labels have both singular and plural versions in the tree, so remove the duplicates.
    # - User, Author... Models we do not care about for checking relations
    names.flatten.uniq - ['milestones', 'labels', 'user', 'author'] + ['project']
  end

  let(:all_models_yml) { 'spec/lib/gitlab/import_export/all_models.yml' }
  let(:all_models) { YAML.load_file(all_models_yml) }
  let(:current_models) { setup_models }

  it 'has no new models' do
    relation_names.each do |relation_name|
      new_models = current_models[relation_name] - all_models[relation_name]
      expect(new_models).to be_empty, failure_message(relation_name.classify, new_models)
    end
  end

  # List of current relations between models, in the format of
  # {model: [model_2, model3], ...}
  def setup_models
    all_models_hash = {}

    relation_names.each do |relation_name|
      relation_class = relation_class_for_name(relation_name)

      all_models_hash[relation_name] = relation_class.reflect_on_all_associations.map do |association|
        association.name.to_s
      end
    end

    all_models_hash
  end

  def failure_message(parent_model_name, new_models)
    <<-MSG
      New model(s) <#{new_models.join(',')}> have been added, related to #{parent_model_name}, which is exported by
      the Import/Export feature.

      If you don't think this should be exported, please add it to MODELS_JSON, inside the #{parent_model_name} hash.
      If you think we should export this new model, please add it to IMPORT_EXPORT_CONFIG and to MODELS_JSON.

      MODELS_JSON: #{File.expand_path(all_models_yml)}
      IMPORT_EXPORT_CONFIG: #{Gitlab::ImportExport.config_file}
    MSG
  end
end
