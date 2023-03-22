# frozen_string_literal: true

module Features
  module MergeRequestHelpers
    def preload_view_requirements(merge_request, note)
      # This will load the status fields of the author of the note and merge request
      # to avoid queries when rendering the view being tested.
      #
      merge_request.author.status
      note.author.status
    end

    def serialize_issuable_sidebar(user, project, merge_request)
      MergeRequestSerializer
        .new(current_user: user, project: project)
        .represent(merge_request, serializer: 'sidebar')
    end
  end
end
