# frozen_string_literal: true

module Tooling
  module Danger
    module SettingsSections
      def check!
        return if helper.stable_branch?

        changed_code_files = helper.changed_files(/\.(haml|vue)$/)
        return if changed_code_files.empty?

        vc_regexp = /(SettingsBlockComponent|settings-block|SettingsSectionComponent|settings-section)/
        lines_with_matches = filter_changed_lines(changed_code_files, vc_regexp)
        return if lines_with_matches.empty?

        markdown(<<~MARKDOWN)
            ## Searchable setting sections

            Looks like you have edited the template of some settings section. Please check that all changed sections are still searchable:

            - If you created a new section, make sure to add it to either `lib/search/project_settings.rb` or `lib/search/group_settings.rb`, or in their counterparts in `ee/` if this section is only available behind a licensed feature.
            - If you removed a section, make sure to also remove it from the files above.
            - If you changed a section's id, please update it also in the files above.
            - If you just moved code around within the same page, there is nothing to do.
            - If you are unsure what to do, please reach out to ~"group::personal productivity".

        MARKDOWN

        lines_with_matches.each do |file, lines|
          markdown(<<~MARKDOWN)
              #### `#{file}`

              ```shell
              #{lines.join("\n")}
              ```

          MARKDOWN
        end
      end

      def filter_changed_lines(files, pattern)
        files_with_lines = {}
        files.each do |file|
          next if file.start_with?('spec/', 'ee/spec/', 'qa/',
            'app/views/admin', 'ee/app/views/admin',
            'app/views/profiles', 'ee/app/views/profiles')

          matching_changed_lines = helper.changed_lines(file).select { |line| line =~ pattern }
          next unless matching_changed_lines.any?

          files_with_lines[file] = matching_changed_lines
        end

        files_with_lines
      end
    end
  end
end
