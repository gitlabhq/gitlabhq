# frozen_string_literal: true

require 'spec_helper'

# Part of the test security suite for the Import/Export feature
# Checks whether there are new reference attributes ending with _id in models that are currently being exported as part of the
# project Import/Export feature.
# If there are new references (foreign keys), these will have to either be replaced with actual relation
# or to be blacklisted by using the import_export.yml configuration file.
# Likewise, new models added to import_export.yml, will need to be added with their correspondent relations
# to this spec.
RSpec.describe 'Import/Export Project configuration' do
  include ConfigurationHelper

  where(:relation_path, :relation_name) do
    relation_paths_for(:project).map do |relation_names|
      next if relation_names.last == :author

      [relation_names.join("."), relation_names.last]
    end.compact
  end

  with_them do
    context "where relation #{params[:relation_path]}" do
      it 'does not have prohibited keys' do
        relation_class = relation_class_for_name(relation_name)
        relation_attributes = relation_class.new.attributes.keys - relation_class.encrypted_attributes.keys.map(&:to_s)
        current_attributes = parsed_attributes(relation_name, relation_attributes)
        prohibited_keys = current_attributes.select do |attribute|
          prohibited_key?(attribute) || !relation_class.attribute_method?(attribute)
        end
        expect(prohibited_keys).to be_empty, failure_message(relation_class.to_s, prohibited_keys)
      end
    end
  end

  def failure_message(relation_class, prohibited_keys)
    <<-MSG
      It looks like #{relation_class}, which is exported using the project Import/Export, has references: #{prohibited_keys.join(',')}

      Please replace it with actual relation in IMPORT_EXPORT_CONFIG if they can be exported.

      Please denylist the attribute(s) in IMPORT_EXPORT_CONFIG by adding it to its corresponding
      model in the +excluded_attributes+ section.

      IMPORT_EXPORT_CONFIG: #{Gitlab::ImportExport.config_file}
    MSG
  end
end
