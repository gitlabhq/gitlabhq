# frozen_string_literal: true

require 'gitlab/utils/strong_memoize'

module Tooling
  module DastVariables
    module Docs
      module Helper
        TABLE_HEADER = <<~MD
          | CI/CD variable | Type | Example | Description |
          | :------------- | :--- | ------- | :---------- |
        MD

        def render_variables_table(filter)
          case filter
          when 'site'
            variables = Gitlab::Security::DastVariables.data[:site].filter { |_, variable| !variable[:auth] }
          when 'scanner'
            variables = Gitlab::Security::DastVariables.data[:scanner].filter { |_, variable| !variable[:auth] }
          when 'auth'
            variables = Gitlab::Security::DastVariables.auth_variables
          end

          rendered_variables = variables.map { |key, variable| render_variable(key, variable) }.join("\n")

          "#{TABLE_HEADER}#{rendered_variables}\n"
        end

        def render_variable(key, variable)
          render_row(
            "`#{key}`",
            render_type(variable[:type]),
            render_example(variable[:example]),
            render_description(variable[:description])
          )
        end

        def render_example(example)
          case example
          when nil then ''
          else "`#{example}`"
          end
        end

        def render_type(type)
          case type
          when 'Duration string' then '[Duration string](https://pkg.go.dev/time#ParseDuration)'
          when 'selector' then '[selector](authentication.md#finding-an-elements-selector)'
          else type
          end
        end

        def render_description(description)
          # replace help_page_path-generated documentation links
          # with relative paths to documentation files
          description
            .sub(
              Gitlab::Security::DastVariables.ci_variables_documentation_link,
              '../../../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui'
            )
            .sub(
              Gitlab::Security::DastVariables.vulnerability_checks_documentation_link,
              '../checks/_index.md'
            )
            .sub(
              Gitlab::Security::DastVariables.secure_log_level_documentation_link,
              '../troubleshooting.md#secure_log_level'
            )
            .sub(
              Gitlab::Security::DastVariables.authentication_actions_documentation_link,
              'authentication.md#taking-additional-actions-after-submitting-the-login-form'
            )
        end

        def render_row(*values)
          "| #{values.map { |val| val.to_s.squish }.join(' | ')} |"
        end
      end
    end
  end
end
