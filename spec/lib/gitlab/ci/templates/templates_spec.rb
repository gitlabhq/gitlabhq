# frozen_string_literal: true

require 'spec_helper'

describe "CI YML Templates" do
  ABSTRACT_TEMPLATES = %w[Serverless].freeze

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
        expect { Gitlab::Ci::YamlProcessor.new(template.content) }
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
