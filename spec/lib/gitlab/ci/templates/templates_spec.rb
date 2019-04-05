# frozen_string_literal: true

require 'spec_helper'

describe "CI YML Templates" do
  ABSTRACT_TEMPLATES = %w[Serverless].freeze
  # These templates depend on the presence of the `project`
  # param to enable processing of `include:` within CI config.
  PROJECT_DEPENDENT_TEMPLATES = %w[Auto-DevOps DAST].freeze

  def self.concrete_templates
    Gitlab::Template::GitlabCiYmlTemplate.all.reject do |template|
      ABSTRACT_TEMPLATES.include?(template.name)
    end
  end

  def self.abstract_templates
    Gitlab::Template::GitlabCiYmlTemplate.all.select do |template|
      ABSTRACT_TEMPLATES.include?(template.name)
    end
  end

  describe 'concrete templates with CI/CD jobs' do
    concrete_templates.each do |template|
      it "#{template.name} template should be valid" do
        # Trigger processing of included files
        project = create(:project, :test_repo) if PROJECT_DEPENDENT_TEMPLATES.include?(template.name)

        expect { Gitlab::Ci::YamlProcessor.new(template.content, project: project) }
          .not_to raise_error
      end
    end
  end

  describe 'abstract templates without concrete jobs defined' do
    abstract_templates.each do |template|
      it "#{template.name} template should be valid after being implemented" do
        content = template.content + <<~EOS
          concrete_build_implemented_by_a_user:
            stage: build
            script: do something
        EOS

        expect { Gitlab::Ci::YamlProcessor.new(content) }.not_to raise_error
      end
    end
  end
end
