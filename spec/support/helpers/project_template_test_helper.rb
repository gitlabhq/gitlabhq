# frozen_string_literal: true

module ProjectTemplateTestHelper
  def all_templates
    %w[
      rails spring express iosswift dotnetcore android
      gomicro astro hugo jekyll nextjs nuxt plainhtml
      gitpod_spring_petclinic salesforcedx
      serverless_framework tencent_serverless_framework
      jsonnet cluster_management kotlin_native_linux
      typo3_distribution laravel nist_80053r5 gitlab_components
    ]
  end
end

ProjectTemplateTestHelper.prepend_mod
