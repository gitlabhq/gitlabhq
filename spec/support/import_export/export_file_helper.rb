require './spec/support/import_export/configuration_helper'

module ExportFileHelper
  include ConfigurationHelper

  ObjectWithParent = Struct.new(:object, :parent, :key_found)

  def setup_project
    project = create(:project, :public, :repository)

    create(:release, project: project)

    issue = create(:issue, assignees: [user], project: project)
    snippet = create(:project_snippet, project: project)
    label = create(:label, project: project)
    milestone = create(:milestone, project: project)
    merge_request = create(:merge_request, source_project: project, milestone: milestone)
    commit_status = create(:commit_status, project: project)

    create(:label_link, label: label, target: issue)

    ci_pipeline = create(:ci_pipeline,
                         project: project,
                         sha: merge_request.diff_head_sha,
                         ref: merge_request.source_branch,
                         statuses: [commit_status])

    create(:ci_build, pipeline: ci_pipeline, project: project)
    create(:milestone, project: project)
    create(:note, noteable: issue, project: project)
    create(:note, noteable: merge_request, project: project)
    create(:note, noteable: snippet, project: project)
    create(:note_on_commit,
           author: user,
           project: project,
           commit_id: ci_pipeline.sha)

    event = create(:event, :created, target: milestone, project: project, author: user, action: 5)
    create(:push_event_payload, event: event)
    create(:project_member, :master, user: user, project: project)
    create(:ci_variable, project: project)
    create(:ci_trigger, project: project)
    key = create(:deploy_key)
    key.projects << project
    create(:service, project: project)
    create(:project_hook, project: project, token: 'token')
    create(:protected_branch, project: project)

    project
  end

  # Expands the compressed file for an exported project into +tmpdir+
  def in_directory_with_expanded_export(project)
    Dir.mktmpdir do |tmpdir|
      export_file = project.export_project_path
      _output, exit_status = Gitlab::Popen.popen(%W{tar -zxf #{export_file} -C #{tmpdir}})

      yield(exit_status, tmpdir)
    end
  end

  # Recursively finds key/values including +key+ as part of the key, inside a nested hash
  def deep_find_with_parent(sensitive_key_word, object, found = nil)
    sensitive_key_found = object_contains_key?(object, sensitive_key_word)

    # Returns the parent object and the object found containing a sensitive word as part of the key
    if sensitive_key_found && object[sensitive_key_found]
      ObjectWithParent.new(object[sensitive_key_found], object, sensitive_key_found)
    elsif object.is_a?(Enumerable)
      # Recursively lookup for keys containing sensitive words in a Hash or Array
      object_with_parent = nil

      object.find do |*hash_or_array|
        object_with_parent = deep_find_with_parent(sensitive_key_word, hash_or_array.last, found)
      end

      object_with_parent
    end
  end

  # Return true if the hash has a key containing a sensitive word
  def object_contains_key?(object, sensitive_key_word)
    return false unless object.is_a?(Hash)

    object.keys.find { |key| key.include?(sensitive_key_word) }
  end

  # Returns the offended ObjectWithParent object if a sensitive word is found inside a hash,
  # excluding the whitelisted safe hashes.
  def find_sensitive_attributes(sensitive_word, project_hash)
    loop do
      object_with_parent = deep_find_with_parent(sensitive_word, project_hash)

      return nil unless object_with_parent && object_with_parent.object

      if is_safe_hash?(object_with_parent.parent, sensitive_word)
        # It's in the safe list, remove hash and keep looking
        object_with_parent.parent.delete(object_with_parent.key_found)
      else
        return object_with_parent
      end

      nil
    end
  end

  # Returns true if it's one of the excluded models in +safe_list+
  def is_safe_hash?(parent, sensitive_word)
    return false unless parent && safe_list[sensitive_word.to_sym]

    # Extra attributes that appear in a model but not in the exported hash.
    excluded_attributes = ['type']

    safe_list[sensitive_word.to_sym].each do |model|
      # Check whether this is a hash attribute inside a model
      if model.is_a?(Symbol)
        return true if (safe_hashes[model] - parent.keys).empty?
      else
        return true if safe_model?(model, excluded_attributes, parent)
      end
    end

    false
  end

  # Compares model attributes with those those found in the hash
  # and returns true if there is a match, ignoring some excluded attributes.
  def safe_model?(model, excluded_attributes, parent)
    excluded_attributes += associations_for(model)
    parsed_model_attributes = parsed_attributes(model.name.underscore, model.attribute_names)

    (parsed_model_attributes - parent.keys - excluded_attributes).empty?
  end

  def file_permissions(file)
    File.stat(file).mode & 0777
  end
end
