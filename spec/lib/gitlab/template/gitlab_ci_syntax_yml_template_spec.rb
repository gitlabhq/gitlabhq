# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Template::GitlabCiSyntaxYmlTemplate do
  subject { described_class }

  describe '#content' do
    it 'loads the full file' do
      template = subject.new(Rails.root.join('lib/gitlab/ci/syntax_templates/Artifacts example.gitlab-ci.yml'))

      expect(template.content).to start_with('#')
    end
  end

  it_behaves_like 'file template shared examples', 'Artifacts example', '.gitlab-ci.yml'
end
