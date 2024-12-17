# frozen_string_literal: true

# Helper methods for Gitea user mapping specs
module Import
  module GiteaHelper
    # This method allows a project to receive two message chains to check the
    # user mapping state of a project.
    def stub_user_mapping_chain(project, user_mapping_enabled)
      allow(project).to receive_message_chain(:import_data, :reset, :user_mapping_enabled?)
                          .and_return(user_mapping_enabled)

      allow(project).to receive_message_chain(:import_data, :user_mapping_enabled?)
                          .and_return(user_mapping_enabled)
    end
  end
end
