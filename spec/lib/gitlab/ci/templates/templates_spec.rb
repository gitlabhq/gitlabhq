# frozen_string_literal: true

require 'spec_helper'

describe "CI YML Templates" do
  using RSpec::Parameterized::TableSyntax

  subject { Gitlab::Ci::YamlProcessor.new(content) }

  where(:template_name) do
    Gitlab::Template::GitlabCiYmlTemplate.all.map(&:full_name)
  end

  with_them do
    let(:content) do
      <<~EOS
        include:
          - template: #{template_name}

        concrete_build_implemented_by_a_user:
          stage: test
          script: do something
      EOS
    end

    it 'is valid' do
      expect { subject }.not_to raise_error
    end

    it 'require default stages to be included' do
      expect(subject.stages).to include(*Gitlab::Ci::Config::Entry::Stages.default)
    end
  end
end
