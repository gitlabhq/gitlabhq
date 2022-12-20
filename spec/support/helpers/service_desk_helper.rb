# frozen_string_literal: true

module ServiceDeskHelper
  def set_template_file(file_name, content)
    file_path = ".gitlab/issue_templates/#{file_name}.md"
    project.repository.create_file(user, file_path, content, message: 'message', branch_name: 'master')
    settings.update!(issue_template_key: file_name)
  end
end
