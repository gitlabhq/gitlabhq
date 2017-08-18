require 'spec_helper'

# Part of the test security suite for the Import/Export feature
# Checks whether there are new attributes in models that are currently being exported as part of the
# project Import/Export feature.
# If there are new attributes, these will have to either be added to this spec in case we want them
# to be included as part of the export, or blacklist them using the import_export.yml configuration file.
# Likewise, new models added to import_export.yml, will need to be added with their correspondent attributes
# to this spec.
describe 'Import/Export attribute configuration' do
  include ConfigurationHelper

  let(:config_hash) { YAML.load_file(Gitlab::ImportExport.config_file).deep_stringify_keys }
  let(:relation_names) do
    names = names_from_tree(config_hash['project_tree'])

    # Remove duplicated or add missing models
    # - project is not part of the tree, so it has to be added manually.
    # - milestone, labels have both singular and plural versions in the tree, so remove the duplicates.
    names.flatten.uniq - %w(milestones labels) + ['project']
  end

  let(:safe_attributes_file) { 'spec/lib/gitlab/import_export/safe_model_attributes.yml' }
  let(:safe_model_attributes) { YAML.load_file(safe_attributes_file) }

  it 'has no new columns' do
    relation_names.each do |relation_name|
      relation_class = relation_class_for_name(relation_name)
      relation_attributes = relation_class.new.attributes.keys

      expect(safe_model_attributes[relation_class.to_s]).not_to be_nil, "Expected exported class #{relation_class} to exist in safe_model_attributes"

      current_attributes = parsed_attributes(relation_name, relation_attributes)
      safe_attributes = safe_model_attributes[relation_class.to_s]
      new_attributes = current_attributes - safe_attributes

      expect(new_attributes).to be_empty, failure_message(relation_class.to_s, new_attributes)
    end
  end

  def failure_message(relation_class, new_attributes)
    <<-MSG
      It looks like #{relation_class}, which is exported using the project Import/Export, has new attributes: #{new_attributes.join(',')}

      Please add the attribute(s) to SAFE_MODEL_ATTRIBUTES if you consider this can be exported.
      Otherwise, please blacklist the attribute(s) in IMPORT_EXPORT_CONFIG by adding it to its correspondent
      model in the +excluded_attributes+ section.

      SAFE_MODEL_ATTRIBUTES: #{File.expand_path(safe_attributes_file)}
      IMPORT_EXPORT_CONFIG: #{Gitlab::ImportExport.config_file}
    MSG
  end

  class Author < User
  end
end
