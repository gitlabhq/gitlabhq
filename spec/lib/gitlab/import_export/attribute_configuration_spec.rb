# frozen_string_literal: true

require 'spec_helper'

# Part of the test security suite for the Import/Export feature
# Checks whether there are new attributes in models that are currently being exported as part of the
# project Import/Export feature.
# If there are new attributes, these will have to either be added to this spec in case we want them
# to be included as part of the export, or add them to excluded_attributes in the import_export.yml configuration file.
# Likewise, new models added to import_export.yml, will need to be added with their correspondent attributes
# to this spec.
RSpec.describe 'Import/Export attribute configuration', feature_category: :importers do
  include ConfigurationHelper

  let(:safe_attributes_file) { 'spec/lib/gitlab/import_export/safe_model_attributes.yml' }
  let(:safe_model_attributes) { YAML.load_file(safe_attributes_file) }

  it 'has no new columns' do
    relation_names_for(:project).each do |relation_name|
      relation_class = relation_class_for_name(relation_name)
      relation_attributes = relation_class.new.attributes.keys - relation_class.attr_encrypted_attributes.keys.map(&:to_s)

      current_attributes = parsed_attributes(relation_name, relation_attributes)
      safe_attributes = safe_model_attributes[relation_class.to_s].dup || []

      expect(safe_attributes).not_to be_nil, "Expected exported class #{relation_class} to exist in safe_model_attributes"

      new_attributes = current_attributes - safe_attributes

      expect(new_attributes).to be_empty, failure_message(relation_class.to_s, new_attributes)
    end
  end

  def failure_message(relation_class, new_attributes)
    <<-MSG
      It looks like #{relation_class}, which is exported using the project Import/Export, has new attributes: #{new_attributes.join(',')}

      Please add the attribute(s) to SAFE_MODEL_ATTRIBUTES if they can be exported.

      Please denylist the attribute(s) in IMPORT_EXPORT_CONFIG by adding it to its corresponding
      model in the +excluded_attributes+ section.

      SAFE_MODEL_ATTRIBUTES: #{File.expand_path(safe_attributes_file)}
      IMPORT_EXPORT_CONFIG: #{Gitlab::ImportExport.config_file}
    MSG
  end
end
