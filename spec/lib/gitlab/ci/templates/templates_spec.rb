# frozen_string_literal: true

require 'spec_helper'

describe "CI YML Templates" do
  Gitlab::Template::GitlabCiYmlTemplate.all.each do |template|
    it "#{template.name} should be valid" do
      expect { Gitlab::Ci::YamlProcessor.new(template.content) }.not_to raise_error
    end
  end
end
