# frozen_string_literal: true

module OrphanFinalArtifactsCleanupHelpers
  def create_fog_file(final: true)
    path = if final
             JobArtifactUploader.generate_final_store_path(root_id: 123)
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

  def expect_done_log_message
    expect_log_message("Done")
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

  def expect_no_resuming_from_marker_log_message
    expect(Gitlab::AppLogger).not_to have_received(:info).with(a_string_including("Resuming"))
  end

  def expect_delete_log_message(fog_file)
    expect_log_message("Delete #{fog_file.key} (#{fog_file.content_length} bytes)")
  end

  def expect_no_delete_log_message(fog_file)
    expect_no_log_message("Delete #{fog_file.key} (#{fog_file.content_length} bytes)")
  end

  def expect_log_message(message, times: 1)
    message = "[DRY RUN] #{message}" if dry_run
    expect(Gitlab::AppLogger).to have_received(:info).with(a_string_including(message)).exactly(times).times
  end

  def expect_no_log_message(message)
    message = "[DRY RUN] #{message}" if dry_run
    expect(Gitlab::AppLogger).not_to have_received(:info).with(a_string_including(message))
  end

  def fetch_saved_marker
    Gitlab::Redis::SharedState.with do |redis|
      redis.get(described_class::LAST_PAGE_MARKER_REDIS_KEY)
    end
  end
end
