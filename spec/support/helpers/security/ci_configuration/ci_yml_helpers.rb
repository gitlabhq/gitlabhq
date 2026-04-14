# frozen_string_literal: true

module Security
  module CiConfiguration
    module CiYmlHelpers
      SECURITY_TEMPLATE_COMMENTS = <<~COMMENTS
        # You can override the included template(s) by including variable overrides
        # SAST customization: https://docs.gitlab.com/user/application_security/sast/#available-cicd-variables
        # Secret Detection customization: https://docs.gitlab.com/user/application_security/secret_detection/pipeline/configure/
        # Dependency Scanning customization: https://docs.gitlab.com/user/application_security/dependency_scanning/dependency_scanning_sbom/#customizing-analyzer-behavior
        # Container Scanning customization: https://docs.gitlab.com/user/application_security/container_scanning/#customizing-analyzer-behavior
        # Note that environment variables can be set in several places
        # See https://docs.gitlab.com/ci/variables/#cicd-variable-precedence
      COMMENTS
    end
  end
end
