require 'spec_helper'

# Part of the test security suite for the Import/Export feature
# Finds if a new model has been added that can potentially be part of the Import/Export
# If it finds a new model, it will show a +failure_message+ with the options available.
describe 'Import/Export model configuration' do
  include ConfigurationHelper

  let(:config_hash) { YAML.load_file(Gitlab::ImportExport.config_file).deep_stringify_keys }
  let(:model_names) do
    names = names_from_tree(config_hash['project_tree'])

    # Remove duplicated or add missing models
    # - project is not part of the tree, so it has to be added manually.
    # - milestone, labels have both singular and plural versions in the tree, so remove the duplicates.
    # - User, Author... Models we do not care about for checking models
    names.flatten.uniq - %w(milestones labels user author) + ['project']
  end

  let(:all_models_yml) { 'spec/lib/gitlab/import_export/all_models.yml' }
  let(:all_models) { YAML.load_file(all_models_yml) }
  let(:current_models) { setup_models }

  it 'has no new models' do
    model_names.each do |model_name|
      new_models = Array(current_models[model_name]) - Array(all_models[model_name])
      expect(new_models).to be_empty, failure_message(model_name.classify, new_models)
    end
  end

  # List of current models between models, in the format of
  # {model: [model_2, model3], ...}
  def setup_models
    all_models_hash = {}

    model_names.each do |model_name|
      model_class = relation_class_for_name(model_name)

      all_models_hash[model_name] = associations_for(model_class) - ['project']
    end

    all_models_hash
  end

  def failure_message(parent_model_name, new_models)
    <<-MSG
      New model(s) <#{new_models.join(',')}> have been added, related to #{parent_model_name}, which is exported by
      the Import/Export feature.

      If you think this model should be included in the export, please add it to IMPORT_EXPORT_CONFIG.
      Definitely add it to MODELS_JSON to signal that you've handled this error and to prevent it from showing up in the future.

      MODELS_JSON: #{File.expand_path(all_models_yml)}
      IMPORT_EXPORT_CONFIG: #{Gitlab::ImportExport.config_file}
    MSG
  end
end
