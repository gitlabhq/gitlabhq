module MigrationsHelpers
  module TrackUntrackedUploadsHelpers
    PUBLIC_DIR = File.join(Rails.root, 'tmp', 'tests', 'public')
    UPLOADS_DIR = File.join(PUBLIC_DIR, 'uploads')
    SYSTEM_DIR = File.join(UPLOADS_DIR, '-', 'system')
    UPLOAD_FILENAME = 'image.png'.freeze
    FIXTURE_FILE_PATH = File.join(Rails.root, 'spec', 'fixtures', 'dk.png')
    FIXTURE_CHECKSUM = 'b804383982bb89b00e828e3f44c038cc991d3d1768009fc39ba8e2c081b9fb75'.freeze

    def create_or_update_appearance(logo: false, header_logo: false)
      appearance = appearances.first_or_create(title: 'foo', description: 'bar', logo: (UPLOAD_FILENAME if logo), header_logo: (UPLOAD_FILENAME if header_logo))

      add_upload(appearance, 'Appearance', 'logo', 'AttachmentUploader') if logo
      add_upload(appearance, 'Appearance', 'header_logo', 'AttachmentUploader') if header_logo

      appearance
    end

    def create_group(avatar: false)
      index = unique_index(:group)
      group = namespaces.create(name: "group#{index}", path: "group#{index}", avatar: (UPLOAD_FILENAME if avatar))

      add_upload(group, 'Group', 'avatar', 'AvatarUploader') if avatar

      group
    end

    def create_note(attachment: false)
      note = notes.create(attachment: (UPLOAD_FILENAME if attachment))

      add_upload(note, 'Note', 'attachment', 'AttachmentUploader') if attachment

      note
    end

    def create_project(avatar: false)
      group = create_group
      project = projects.create(namespace_id: group.id, path: "project#{unique_index(:project)}", avatar: (UPLOAD_FILENAME if avatar))
      routes.create(path: "#{group.path}/#{project.path}", source_id: project.id, source_type: 'Project') # so Project.find_by_full_path works

      add_upload(project, 'Project', 'avatar', 'AvatarUploader') if avatar

      project
    end

    def create_user(avatar: false)
      user = users.create(email: "foo#{unique_index(:user)}@bar.com", avatar: (UPLOAD_FILENAME if avatar), projects_limit: 100)

      add_upload(user, 'User', 'avatar', 'AvatarUploader') if avatar

      user
    end

    def unique_index(name = :unnamed)
      @unique_index ||= {}
      @unique_index[name] ||= 0
      @unique_index[name] += 1
    end

    def add_upload(model, model_type, attachment_type, uploader)
      file_path = upload_file_path(model, model_type, attachment_type)
      path_relative_to_public = file_path.sub("#{PUBLIC_DIR}/", '')
      create_file(file_path)

      uploads.create!(
        size: 1062,
        path: path_relative_to_public,
        model_id: model.id,
        model_type: model_type == 'Group' ? 'Namespace' : model_type,
        uploader: uploader,
        checksum: FIXTURE_CHECKSUM
      )
    end

    def add_markdown_attachment(project, hashed_storage: false)
      project_dir = hashed_storage ? hashed_project_uploads_dir(project) : legacy_project_uploads_dir(project)
      attachment_dir = File.join(project_dir, SecureRandom.hex)
      attachment_file_path = File.join(attachment_dir, UPLOAD_FILENAME)
      project_attachment_path_relative_to_project = attachment_file_path.sub("#{project_dir}/", '')
      create_file(attachment_file_path)

      uploads.create!(
        size: 1062,
        path: project_attachment_path_relative_to_project,
        model_id: project.id,
        model_type: 'Project',
        uploader: 'FileUploader',
        checksum: FIXTURE_CHECKSUM
      )
    end

    def legacy_project_uploads_dir(project)
      namespace = namespaces.find_by(id: project.namespace_id)
      File.join(UPLOADS_DIR, namespace.path, project.path)
    end

    def hashed_project_uploads_dir(project)
      File.join(UPLOADS_DIR, '@hashed', 'aa', 'aaaaaaaaaaaa')
    end

    def upload_file_path(model, model_type, attachment_type)
      dir = File.join(upload_dir(model_type.downcase, attachment_type.to_s), model.id.to_s)
      File.join(dir, UPLOAD_FILENAME)
    end

    def upload_dir(model_type, attachment_type)
      File.join(SYSTEM_DIR, model_type, attachment_type)
    end

    def create_file(path)
      File.delete(path) if File.exist?(path)
      FileUtils.mkdir_p(File.dirname(path))
      FileUtils.cp(FIXTURE_FILE_PATH, path)
    end

    def get_uploads(model, model_type)
      uploads.where(model_type: model_type, model_id: model.id)
    end

    def get_full_path(project)
      routes.find_by(source_id: project.id, source_type: 'Project').path
    end

    def ensure_temporary_tracking_table_exists
      Gitlab::BackgroundMigration::PrepareUntrackedUploads.new.send(:ensure_temporary_tracking_table_exists)
    end
  end
end
