# frozen_string_literal: true

module WikiHelpers
  extend self

  def wait_for_svg_to_be_loaded(example = nil)
    # Ensure the SVG is loaded first before clicking the button
    find('.svg-content .js-lazy-loaded') if example.nil? || example.metadata.key?(:js)
  end

  def upload_file_to_wiki(project, user, file_name)
    opts = {
      file_name: file_name,
      file_content: File.read(expand_fixture_path(file_name))
     }

    ::Wikis::CreateAttachmentService.new(project, user, opts)
                                    .execute[:result][:file_path]
  end
end
