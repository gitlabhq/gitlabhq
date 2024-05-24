# frozen_string_literal: true

module ProjectTemplateTestHelper
  def all_templates
    %w[
      rails spring express iosswift dotnetcore android
      gomicro gatsby hugo jekyll plainhtml
      hexo middleman gitpod_spring_petclinic nfhugo
      nfjekyll nfplainhtml nfgitbook nfhexo salesforcedx
      serverless_framework tencent_serverless_framework
      jsonnet cluster_management kotlin_native_linux
      pelican bridgetown typo3_distribution laravel
      astro_tailwind nist_80053r5
    ]
  end
end

ProjectTemplateTestHelper.prepend_mod
