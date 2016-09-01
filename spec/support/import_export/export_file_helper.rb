module ExportFileHelper
  def setup_project
    project = create(:project, :public)

    create(:release, project: project)

    issue = create(:issue, assignee: user, project: project)
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

    create(:event, target: milestone, project: project, action: Event::CREATED, author: user)
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
    # Returns the parent object and the object found containing a sensitive word as part of the key
    if object_contains_key?(object, sensitive_key_word)
      [object[sensitive_key_word], object] if object[sensitive_key_word]
    elsif object.is_a?(Enumerable)
      # Recursively lookup for keys containing sensitive words in a Hash or Array
      object.find { |*hash_or_array| found, object = deep_find_with_parent(sensitive_key_word, hash_or_array.last, found) }
      [found, object] if found
    end
  end

  #Return true if the hash has a key containing a sensitive word
  def object_contains_key?(object, sensitive_key_word)
    object.is_a?(Hash) && object.keys.any? { |key| key.include?(sensitive_key_word) }
  end

  # Returns true if a sensitive word is found inside a hash, excluding safe hashes
  def has_sensitive_attributes?(sensitive_word, project_hash)
    loop do
      object, parent = deep_find_with_parent(sensitive_word, project_hash)

      if object && is_safe_hash?(parent, sensitive_word)
        # It's in the safe list, remove hash and keep looking
        parent.delete(object)
      elsif object
        return true
      else
        return false
      end
    end
  end

  # Returns true if it's one of the excluded models in +safe_models+
  def is_safe_hash?(parent, sensitive_word)
    return false unless parent

    # Extra attributes that appear in a model but not in the exported hash.
    excluded_attributes = ['type']

    safe_models[sensitive_word.to_sym].each do |safe_model|
      return true if (safe_model.attribute_names - parent.keys - excluded_attributes).empty?
    end

    false
  end
end
