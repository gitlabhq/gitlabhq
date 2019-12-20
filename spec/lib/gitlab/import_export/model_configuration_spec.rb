# frozen_string_literal: true

require 'spec_helper'

# Part of the test security suite for the Import/Export feature
# Finds if a new model has been added that can potentially be part of the Import/Export
# If it finds a new model, it will show a +failure_message+ with the options available.
describe 'Import/Export model configuration' do
  include ConfigurationHelper

  let(:all_models_yml) { 'spec/lib/gitlab/import_export/all_models.yml' }
  let(:all_models_hash) { YAML.load_file(all_models_yml) }
  let(:current_models) { setup_models }
  let(:model_names) { relation_names_for(:project) }

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

      Definitely add it to `#{File.expand_path(all_models_yml)}`
      to signal that you've handled this error and to prevent it from showing up in the future.
    MSG
  end
end
