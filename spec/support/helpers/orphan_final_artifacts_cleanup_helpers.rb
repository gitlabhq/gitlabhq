# frozen_string_literal: true

module OrphanFinalArtifactsCleanupHelpers
  def create_fog_file(final: true)
    path = if final
             JobArtifactUploader.generate_final_store_path(root_hash: 123)
           else
             JobArtifactUploader.generate_remote_id
           end

    fog_connection.directories.new(key: remote_directory)
      .files
      .create( # rubocop:disable Rails/SaveBang -- not the AR method
        key: path_with_bucket_prefix(path),
        body: 'content'
      )
  end

  def build_dummy_deleted_final_object
    generation = SecureRandom.hex
    create_fog_file.tap do |fog_file|
      allow(fog_file).to receive(:generation).and_return(generation)
    end
  end

  def path_without_bucket_prefix(path)
    Pathname.new(path).relative_path_from(bucket_prefix.to_s).to_s
  end

  def path_with_bucket_prefix(path)
    File.join([bucket_prefix, path].compact)
  end

  def expect_object_to_exist(fog_file)
    expect { fog_connection.get_object(remote_directory, fog_file.key) }.not_to raise_error
  end

  def expect_object_to_be_deleted(fog_file)
    expect { fog_connection.get_object(remote_directory, fog_file.key) }.to raise_error(Excon::Error::NotFound)
  end

  def expect_start_log_message
    expect_log_message("Looking for orphan job artifact objects")
  end

  def expect_done_log_message(filename)
    expect_log_message("Done. All orphan objects are listed in #{filename}.")
  end

  def expect_first_page_loading_log_message
    expect_log_message("Loading page (first page)", times: 1)
  end

  def expect_page_loading_via_marker_log_message(times:)
    expect_log_message("Loading page (marker:", times: times)
  end

  def expect_resuming_from_marker_log_message(marker)
    expect_log_message("Resuming from last page marker: #{marker}", times: 1)
  end

  def expect_resuming_from_cursor_position_log_message(filename, position)
    expect_log_message(
      "Resuming from last cursor position tracked in #{cursor_tracker_redis_key(filename)}: #{position}",
      times: 1
    )
  end

  def expect_no_resuming_from_marker_log_message
    expect(Gitlab::AppLogger).not_to have_received(:info).with(a_string_including("Resuming"))
  end
  alias_method :expect_no_resuming_from_cursor_position_log_message, :expect_no_resuming_from_marker_log_message

  def expect_found_orphan_artifact_object_log_message(fog_file)
    expect_log_message("Found orphan object #{fog_file.key} (#{fog_file.content_length} bytes)")
  end

  def expect_no_found_orphan_artifact_object_log_message(fog_file)
    expect_no_log_message("Found orphan object #{fog_file.key} (#{fog_file.content_length} bytes)")
  end

  def expect_processing_list_log_message(filename)
    expect_log_message("Processing #{filename}", times: 1)
  end

  def expect_skipping_object_with_job_artifact_record_log_message(fog_file)
    expect_log_message(
      "Found job artifact record for object #{path_without_bucket_prefix(fog_file.key)}, skipping.",
      times: 1
    )
  end

  def expect_skipping_non_existent_object_log_message(fog_file)
    expect_log_message(
      "No object found for #{fog_file.key}, skipping.",
      times: 1
    )
  end

  def expect_skipping_object_with_live_version_log_message(fog_file)
    expect_log_message(
      "There is already a live version for object #{fog_file.key}, skipping.",
      times: 1
    )
  end

  def expect_done_deleting_log_message(filename)
    expect_log_message("Done. All deleted objects are listed in #{filename}.", times: 1)
  end

  def expect_deleted_object_log_message(fog_file, times: 1)
    expect_log_message("Deleted object #{fog_file.key} (#{fog_file.content_length} bytes)", times: times)
  end

  def expect_no_deleted_object_log_message(fog_file)
    expect_no_log_message("Deleted object #{fog_file.key} (#{fog_file.content_length} bytes)")
  end

  def expect_rolled_back_deleted_object_log_message(fog_file, times: 1)
    expect_log_message("Rolled back deleted object #{fog_file.key} to generation #{fog_file.generation}", times: times)
  end

  def expect_done_rolling_back_deletion_log_message(filename)
    expect_log_message("Done. Rolled back deleted objects listed in #{filename}.")
  end

  def expect_log_message(message, times: 1)
    expect(Gitlab::AppLogger).to have_received(:info).with(a_string_including(message)).exactly(times).times
  end

  def expect_no_log_message(message)
    expect(Gitlab::AppLogger).not_to have_received(:info).with(a_string_including(message))
  end

  def expect_orphan_objects_list_to_include(lines, fog_file)
    expect(lines).to include([fog_file.key, fog_file.content_length].join(','))
  end

  def expect_orphan_objects_list_not_to_include(lines, fog_file)
    expect(lines).not_to include([fog_file.key, fog_file.content_length].join(','))
  end

  def expect_orphans_list_to_contain_exactly(filename, fog_files)
    lines = File.readlines(filename).map(&:strip)
    expected_objects = fog_files.map { |f| [f.key, f.content_length].join(',') }

    # Given we can't guarantee order of which object will be listed first,
    # we just use match_array.
    expect(lines).to match_array(expected_objects)
  end

  def expect_orphans_list_to_have_number_of_entries(count)
    expect(File.readlines(filename).count).to eq(count)
  end

  def expect_deleted_list_to_contain_exactly(filename, fog_files, includes_generation: false)
    lines = File.readlines(filename).map(&:strip)

    expected_objects = fog_files.map do |f|
      generation = f.generation if includes_generation
      [f.key, f.content_length, generation].compact.join(',')
    end

    expect(lines).to match_array(expected_objects)
  end

  def expect_to_copy_with_source_generation(fog_file)
    expect(fog_file).to receive(:copy).with(
      fog_file.directory.key,
      fog_file.key,
      source_generation: fog_file.generation,
      if_generation_match: 0
    )
  end

  def fetch_saved_marker
    Gitlab::Redis::SharedState.with do |redis|
      redis.get(described_class::LAST_PAGE_MARKER_REDIS_KEY)
    end
  end

  def fetch_saved_cursor_position(filename)
    Gitlab::Redis::SharedState.with do |redis|
      redis.get(cursor_tracker_redis_key(filename))
    end
  end

  def cursor_tracker_redis_key(filename)
    "#{described_class::CURSOR_TRACKER_REDIS_KEY_PREFIX}#{File.basename(filename)}"
  end
end
