# frozen_string_literal: true

require 'spec_helper'

# Documents what happens today when a YAML tag is passed as an `include: inputs:` value.
#
# A tag is only resolved by `Yaml::Tags::Resolver`, which runs on the merged configuration
# after input interpolation. So the unresolved object is what reaches the input layer, and
# the outcome depends on the input's declared type and on how the included file uses the
# value. None of these outcomes are a supported contract.
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

  # `described_class` merges and interpolates but does not run the job schema validations,
  # so cases rejected by a keyword rather than by the input go through the processor.
  let(:processor_result) do
    Gitlab::Ci::YamlProcessor.new(gitlab_ci_yml, project: project, sha: project_sha, user: user).execute
  end

  before do
    allow_next_instance_of(Gitlab::Ci::Config::External::Context) do |instance|
      allow(instance).to receive(:check_execution_time!)
    end
  end

  around do |example|
    create_and_delete_files(project, project_files) { example.run }
  end

  shared_examples 'a dumped tag object' do
    it 'leaks the internal tag object into the configuration' do
      expect(config.to_hash.dig(:job, :script).to_s).to include(
        'Gitlab::Ci::Config::Yaml::Tags::Reference'
      )
    end
  end

  # The value stays an Array, so the array type check passes and the unresolved object
  # rides along inside it until the resolver runs.
  context 'when a tag is an element of an array input value' do
    let(:input_value) { "\n              - !reference [.my-shared-list]\n              - my-specific" }

    it 'resolves the tag' do
      expect(config.to_hash.dig(:job, :script)).to eq([%w[value1 value2], 'my-specific'])
    end

    context 'when the tag points at a scalar' do
      let(:list_content) { ".my-shared-list: hello-from-ref\n" }
      let(:input_value) { "\n              - !reference [.my-shared-list]" }

      it 'resolves the tag to a flat array' do
        expect(config.to_hash.dig(:job, :script)).to eq(['hello-from-ref'])
      end
    end

    context 'when the template interpolates the value inside a string' do
      let(:template_body) { "job:\n  script:\n    - echo '$[[ inputs.a ]]'" }

      it_behaves_like 'a dumped tag object'
    end

    # The tag resolves to whatever it points at, so the keyword receiving the value decides
    # whether the result is accepted. `script:` takes a nested array, `tags:` does not.
    context 'when the resolved value has to satisfy the target keyword' do
      let(:template_body) { "job:\n  tags: $[[ inputs.a ]]\n  script: echo test" }
      let(:input_value) { "\n              - !reference [.my-shared-list]" }

      it 'is rejected when the tag points at a list' do
        expect(processor_result.errors).to include('jobs:job:tags config should be an array of strings')
      end

      context 'when the tag points at a scalar' do
        let(:list_content) { ".my-shared-list: hello-from-ref\n" }

        it 'is accepted' do
          expect(config.to_hash.dig(:job, :tags)).to eq(['hello-from-ref'])
        end
      end
    end
  end

  # The value stays an Array, so the input type check passes, but the tag resolves into a
  # hash that `script:` does not accept.
  context 'when a tag is nested inside a hash in the input value' do
    let(:input_value) { "\n              - key: !reference [.my-shared-list]" }

    it 'is rejected by the job schema rather than by the input' do
      expect(processor_result.errors).to include(
        'jobs:job:script config should be a string or a nested array of strings up to 10 levels deep'
      )
    end
  end

  # The value is the tag object rather than an Array, so the type check rejects it.
  context 'when a tag is the entire input value' do
    let(:input_value) { '!reference [.my-shared-list]' }

    it 'reports a misleading type error' do
      expect { config }.to raise_error(described_class::ConfigError, /`a` input: provided value is not an array/)
    end

    context 'with a string input' do
      let(:input_type) { 'string' }

      it_behaves_like 'a dumped tag object'
    end
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

    it 'reports a misleading type error' do
      expect { config }.to raise_error(described_class::ConfigError, /`a` input: default value is not an array/)
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
