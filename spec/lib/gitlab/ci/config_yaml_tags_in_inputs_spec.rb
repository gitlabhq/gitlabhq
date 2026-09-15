# frozen_string_literal: true

require 'spec_helper'

# End-to-end coverage for rejecting YAML tags passed as `include: inputs:` values.
# See https://gitlab.com/gitlab-org/gitlab/-/issues/607053.
RSpec.describe Gitlab::Ci::Config, feature_category: :pipeline_composition do
  include RepoHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :small_repo, group: group) }

  let(:project_sha) { project.commit.id }

  let(:list_content) do
    <<~YAML
      .my-shared-list:
        - value1
        - value2
    YAML
  end

  let(:input_type) { 'array' }
  let(:template_body) { "job:\n  script: $[[ inputs.a ]]" }

  let(:template_content) do
    <<~YAML
      spec:
        inputs:
          a:
            type: #{input_type}
      ---
      #{template_body}
    YAML
  end

  let(:input_value) { raise NotImplementedError }

  let(:gitlab_ci_yml) do
    <<~YAML
      include:
        - local: /list.yml
        - local: /template.yml
          inputs:
            a: #{input_value}
    YAML
  end

  let(:project_files) do
    {
      'list.yml' => list_content,
      'template.yml' => template_content
    }
  end

  let(:config) do
    described_class.new(gitlab_ci_yml, project: project, pipeline: nil, sha: project_sha, user: user)
  end

  before do
    allow_next_instance_of(Gitlab::Ci::Config::External::Context) do |instance|
      allow(instance).to receive(:check_execution_time!)
    end
  end

  around do |example|
    create_and_delete_files(project, project_files) { example.run }
  end

  shared_examples 'a rejected input value' do |error_message|
    it 'rejects the value with a clear error' do
      expect { config }.to raise_error(described_class::ConfigError, /#{error_message}/)
    end
  end

  context 'when a tag is the entire input value' do
    let(:input_value) { '!reference [.my-shared-list]' }

    it_behaves_like 'a rejected input value', 'provided value cannot contain a !reference tag'

    context 'when used embedded in a string' do
      let(:template_body) { "job:\n  script:\n    - echo '$[[ inputs.a ]]'" }

      it_behaves_like 'a rejected input value', 'provided value cannot contain a !reference tag'
    end

    context 'with a scalar input' do
      let(:input_type) { 'string' }
      let(:list_content) { ".my-shared-list: hello-from-ref\n" }

      it_behaves_like 'a rejected input value', 'provided value cannot contain a !reference tag'
    end
  end

  context 'when a tag is nested inside the input value' do
    let(:input_value) { "\n              - !reference [.my-shared-list]\n              - my-specific" }

    it_behaves_like 'a rejected input value', 'provided value cannot contain a !reference tag'
  end

  context 'when a tag is nested inside a hash in the input value' do
    let(:input_value) { "\n              - key: !reference [.my-shared-list]" }

    it_behaves_like 'a rejected input value', 'provided value cannot contain a !reference tag'
  end

  context 'when a tag is in the input default value' do
    let(:gitlab_ci_yml) do
      <<~YAML
        include:
          - local: /list.yml
          - local: /template.yml
      YAML
    end

    let(:template_content) do
      <<~YAML
        spec:
          inputs:
            a:
              type: array
              default: !reference [.my-shared-list]
        ---
        job:
          script: $[[ inputs.a ]]
      YAML
    end

    it_behaves_like 'a rejected input value', 'default value cannot contain a !reference tag'
  end

  context 'when the feature flag is disabled' do
    before do
      stub_feature_flags(ci_reject_yaml_tags_in_inputs: false)
    end

    let(:input_value) { "\n              - !reference [.my-shared-list]\n              - my-specific" }
    let(:template_body) { "job:\n  script:\n    - echo '$[[ inputs.a ]]'" }

    it 'keeps the previous behavior and leaks the internal tag object' do
      expect(config.to_hash.dig(:job, :script).first).to include(
        'Gitlab::Ci::Config::Yaml::Tags::Reference'
      )
    end
  end

  context 'without a YAML tag' do
    let(:input_value) { "\n              - plain-value" }

    it 'interpolates the input normally' do
      expect(config.to_hash.dig(:job, :script)).to eq(['plain-value'])
    end
  end

  context 'when a tag is used outside the input values' do
    let(:input_value) { "\n              - plain-value" }
    let(:template_body) { "job:\n  before_script: !reference [.my-shared-list]\n  script: $[[ inputs.a ]]" }

    it 'resolves the tag and interpolates the input' do
      expect(config.to_hash[:job]).to include(
        before_script: %w[value1 value2],
        script: ['plain-value']
      )
    end
  end

  context 'when the input value is a quoted string that looks like a tag' do
    let(:input_type) { 'string' }
    let(:input_value) { '"!reference [.my-shared-list]"' }

    it 'keeps the value as plain text' do
      expect(config.to_hash.dig(:job, :script)).to eq('!reference [.my-shared-list]')
    end
  end
end
