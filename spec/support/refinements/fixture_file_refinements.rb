# frozen_string_literal: true

module FixtureFileRefinements
  refine Rack::Test::UploadedFile do
    # Recast this instance of `Rack::Test::UploadedFile` to an `::UploadedFile`.
    def to_gitlab_uploaded_file
      ::UploadedFile.new(path, filename: original_filename, content_type: content_type || 'application/octet-stream').tap do |file|
        # `UploadedFile#tempfile` is read-only, so replace this with the writeable fixture file
        file.instance_variable_set(:@tempfile, self)
      end
    end

    # Renames `original_filename` to something guaranteed to be unique.
    def uniquely_named
      name = File.basename(FactoryBot.generate(:filename), '.*')
      extension = File.extname(original_filename)
      unique_filename = name + extension

      renamed_as(unique_filename)
    end

    def renamed_as(new_filename)
      tap { @original_filename = new_filename }
    end
  end
end
