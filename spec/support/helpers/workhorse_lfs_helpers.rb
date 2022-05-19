# frozen_string_literal: true

module WorkhorseLfsHelpers
  extend self

  def put_finalize(
    lfs_tmp = nil, with_tempfile: false, verified: true, remote_object: nil,
    args: {}, to_project: nil, size: nil, sha256: nil)

    lfs_tmp ||= "#{sample_oid}012345678"
    to_project ||= project
    uploaded_file =
      if with_tempfile
        upload_path = LfsObjectUploader.workhorse_local_upload_path
        file_path = upload_path + '/' + lfs_tmp

        FileUtils.mkdir_p(upload_path)
        FileUtils.touch(file_path)
        File.truncate(file_path, sample_size)

        UploadedFile.new(file_path, filename: File.basename(file_path), sha256: sample_oid)
      elsif remote_object
        fog_to_uploaded_file(remote_object, sha256: sample_oid)
      else
        UploadedFile.new(
          nil,
          size: size || sample_size,
          sha256: sha256 || sample_oid,
          remote_id: 'remote id'
        )
      end

    finalize_headers = headers
    finalize_headers.merge!(workhorse_internal_api_request_header) if verified

    workhorse_finalize(
      objects_url(to_project, sample_oid, sample_size),
      method: :put,
      file_key: :file,
      params: args.merge(file: uploaded_file),
      headers: finalize_headers,
      send_rewritten_field: include_workhorse_jwt_header
    )
  end
end
