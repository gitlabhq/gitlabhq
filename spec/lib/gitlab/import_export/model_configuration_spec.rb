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
  let(:ce_models_yml) { 'spec/lib/gitlab/import_export/all_models.yml' }
  let(:ce_models_hash) { YAML.load_file(ce_models_yml) }

  let(:ee_models_yml) { 'ee/spec/lib/gitlab/import_export/all_models.yml' }
  let(:ee_models_hash) { File.exist?(ee_models_yml) ? YAML.load_file(ee_models_yml) : {} }

  let(:current_models) { setup_models }
  let(:all_models_hash) do
    all_models_hash = ce_models_hash.dup

    all_models_hash.each do |model, associations|
      associations.concat(ee_models_hash[model] || [])
    end

    ee_models_hash.each do |model, associations|
      all_models_hash[model] ||= associations
    end

    all_models_hash
  end

  it 'has no new models' do
    model_names.each do |model_name|
      new_models = Array(current_models[model_name]) - Array(all_models_hash[model_name])
      expect(new_models).to be_empty, failure_message(model_name.classify, new_models)
    end
  end

  # List of current models between models, in the format of
  # {model: [model_2, model3], ...}
  def setup_models
    model_names.each_with_object({}) do |model_name, hash|
      hash[model_name] = associations_for(relation_class_for_name(model_name)) - ['project']
    end
  end

  def failure_message(parent_model_name, new_models)
    <<~MSG
      New model(s) <#{new_models.join(',')}> have been added, related to #{parent_model_name}, which is exported by
      the Import/Export feature.

      If you think this model should be included in the export, please add it to `#{Gitlab::ImportExport.config_file}`.

      Definitely add it to `#{File.expand_path(ce_models_yml)}`
      #{"or `#{File.expand_path(ee_models_yml)}` if the model/associations are EE-specific\n" if ee_models_hash.any?}
      to signal that you've handled this error and to prevent it from showing up in the future.
    MSG
  end
end
