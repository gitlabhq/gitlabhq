# frozen_string_literal: true

module ProjectTemplateTestHelper
  def all_templates
    %w[
      rails spring express dotnetcore android
      astro docusaurus hugo jekyll nextjs nuxt plainhtml
      cluster_management typo3_distribution nist_80053r5 gitlab_components
    ]
  end
end

ProjectTemplateTestHelper.prepend_mod
