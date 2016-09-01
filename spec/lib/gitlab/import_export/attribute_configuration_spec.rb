require 'spec_helper'

# Checks whether there are new attributes in models that are currently being exported as part of the
# project Import/Export feature.
# If there are new attributes, these will have to either be added to this spec in case we want them
# to be included as part of the export, or blacklist them using the import_export.yml configuration file.
# Likewise, new models added to import_export.yml, will need to be added with their correspondent attributes
# to this spec.
describe 'Attribute configuration', lib: true do
  let(:config_hash) { YAML.load_file(Gitlab::ImportExport.config_file).deep_stringify_keys }
  let(:relation_names) do
    names = names_from_tree(config_hash['project_tree'])

    # Remove duplicated or add missing models
    # - project is not part of the tree, so it has to be added manually.
    # - milestone, labels have both singular and plural versions in the tree, so remove the duplicates.
    names.flatten.uniq - ['milestones', 'labels'] + ['project']
  end

  let(:safe_model_attributes) do
    {
      'Issue' => %w[id title assignee_id author_id project_id created_at updated_at position branch_name description state iid updated_by_id confidential deleted_at due_date moved_to_id lock_version milestone_id weight],
      'Event' => %w[id target_type target_id title data project_id created_at updated_at action author_id],
      'Note' => %w[id note noteable_type author_id created_at updated_at project_id attachment line_code commit_id noteable_id system st_diff updated_by_id type position original_position resolved_at resolved_by_id discussion_id original_discussion_id],
      'LabelLink' => %w[id label_id target_id target_type created_at updated_at],
      'Label' => %w[id title color project_id created_at updated_at template description priority],
      'Milestone' => %w[id title project_id description due_date created_at updated_at state iid],
      'ProjectSnippet' => %w[id title content author_id project_id created_at updated_at file_name type visibility_level],
      'Release' => %w[id tag description project_id created_at updated_at],
      'ProjectMember' => %w[id access_level source_id source_type user_id notification_level type created_at updated_at created_by_id invite_email invite_token invite_accepted_at requested_at expires_at],
      'User' => %w[id username email],
      'MergeRequest' => %w[id target_branch source_branch source_project_id author_id assignee_id title created_at updated_at state merge_status target_project_id iid description position locked_at updated_by_id merge_error merge_params merge_when_build_succeeds merge_user_id merge_commit_sha deleted_at in_progress_merge_commit_sha lock_version milestone_id approvals_before_merge rebase_commit_sha],
      'MergeRequestDiff' => %w[id state st_commits merge_request_id created_at updated_at base_commit_sha real_size head_commit_sha start_commit_sha],
      'Ci::Pipeline' => %w[id project_id ref sha before_sha push_data created_at updated_at tag yaml_errors committed_at gl_project_id status started_at finished_at duration user_id],
      'CommitStatus' => %w[id project_id status finished_at trace created_at updated_at started_at runner_id coverage commit_id commands job_id name deploy options allow_failure stage trigger_request_id stage_idx tag ref user_id type target_url description artifacts_file gl_project_id artifacts_metadata erased_by_id erased_at artifacts_expire_at environment artifacts_size when yaml_variables queued_at],
      'Ci::Variable' => %w[id project_id key value encrypted_value encrypted_value_salt encrypted_value_iv gl_project_id],
      'Ci::Trigger' => %w[id token project_id deleted_at created_at updated_at gl_project_id],
      'DeployKey' => %w[id user_id created_at updated_at key title type fingerprint public],
      'Service' => %w[id type title project_id created_at updated_at active properties template push_events issues_events merge_requests_events tag_push_events note_events pipeline_events build_events category default wiki_page_events],
      'ProjectHook' => %w[id url project_id created_at updated_at type service_id push_events issues_events merge_requests_events tag_push_events note_events pipeline_events enable_ssl_verification build_events wiki_page_events token group_id],
      'ProtectedBranch' => %w[id project_id name created_at updated_at],
      'Project' => %w[description issues_enabled merge_requests_enabled wiki_enabled snippets_enabled visibility_level archived],
      'Author' => %w[name]
    }
  end

  it 'has no new columns' do
    relation_names.each do |relation_name|
      relation_class = relation_class_for_name(relation_name)

      expect(safe_model_attributes[relation_class.to_s]).not_to be_nil, "Expected exported class #{relation_class.to_s} to exist in safe_model_attributes"

      current_attributes = parsed_attributes(relation_name, relation_class.attribute_names)
      safe_attributes = safe_model_attributes[relation_class.to_s]
      new_attributes = current_attributes - safe_attributes

      expect(new_attributes).to be_empty, failure_message(relation_class.to_s, new_attributes)
    end
  end

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

  def failure_message(relation_class, new_attributes)
    <<-MSG
      It looks like #{relation_class}, which is exported using the project Import/Export, has new attributes: #{new_attributes.join(',')}

      Please add the attribute(s) to +safe_model_attributes+ in CURRENT_SPEC if you consider this can be exported.
      Otherwise, please blacklist the attribute(s) in IMPORT_EXPORT_CONFIG by adding it to its correspondent
      model in the +excluded_attributes+ section.

      CURRENT_SPEC: #{__FILE__}
      IMPORT_EXPORT_CONFIG: #{Gitlab::ImportExport.config_file}
    MSG
  end

  def parsed_attributes(relation_name, attributes)
    excluded_attributes = config_hash['excluded_attributes'][relation_name]
    included_attributes = config_hash['included_attributes'][relation_name]

    attributes = attributes - JSON[excluded_attributes.to_json] if excluded_attributes
    attributes = attributes & JSON[included_attributes.to_json] if included_attributes

    attributes
  end

  class Author < User
  end
end
