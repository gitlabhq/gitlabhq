# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project.ciPipelineCreationInputs', feature_category: :pipeline_composition do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let_it_be(:config_yaml_without_inputs) do
    <<~YAML
    job:
      script: echo hello world
    YAML
  end

  let_it_be(:config_yaml) do
    <<~YAML
    spec:
      inputs:
        mandatory_string_input:
        mandatory_number_input:
          type: number
        mandatory_boolean_input:
          type: boolean
          description: 'Mandatory boolean input'
        mandatory_array_input:
          type: array
        optional_string_input:
          type: string
          default: 'default-value'
        optional_number_input:
          type: number
          default: 1
        optional_boolean_input:
          type: boolean
          default: true
          description: 'Optional boolean input'
        optional_array_input:
          type: array
          default: [{ a: 1 }, { b: 2}]
        string_input_with_options:
          options: ['option1', 'option2', 'option3']
        number_input_with_options:
          type: number
          options: [1, 2, 3]
        string_input_with_regex:
          regex: '[a-z]+'
    ---
    job:
      script: echo hello world
    YAML
  end

  let(:query) do
    <<~GQL
      query {
        project(fullPath: "#{project.full_path}") {
          ciPipelineCreationInputs(ref: "#{ref}") {
            name
            type
            description
            required
            default
            options
            regex
          }
        }
      }
    GQL
  end

  before_all do
    project.repository.create_file(
      project.creator,
      '.gitlab-ci.yml',
      config_yaml,
      message: 'Add CI',
      branch_name: 'master')

    project.repository.create_file(
      project.creator,
      '.gitlab-ci.yml',
      config_yaml_without_inputs,
      message: 'Add CI',
      branch_name: 'feature-no-inputs')
  end

  context 'when current user has access to the project' do
    before_all do
      project.add_developer(user)
    end

    before do
      allow(Gitlab::Ci::Config::FeatureFlags).to receive(:enabled?)
        .with(:ci_file_inputs)
        .and_return(true)
    end

    context 'when inputs exist' do
      let(:ref) { 'master' }

      it 'returns the inputs' do
        post_graphql(query, current_user: user)

        expect(graphql_data['project']).to eq({
          'ciPipelineCreationInputs' => [
            {
              'name' => 'mandatory_string_input',
              'type' => 'STRING',
              'description' => nil,
              'required' => true,
              'default' => nil,
              'options' => nil,
              'regex' => nil
            },
            {
              'name' => 'mandatory_number_input',
              'type' => 'NUMBER',
              'description' => nil,
              'required' => true,
              'default' => nil,
              'options' => nil,
              'regex' => nil
            },
            {
              'name' => 'mandatory_boolean_input',
              'type' => 'BOOLEAN',
              'description' => 'Mandatory boolean input',
              'required' => true,
              'default' => nil,
              'options' => nil,
              'regex' => nil
            },
            {
              'name' => 'mandatory_array_input',
              'type' => 'ARRAY',
              'description' => nil,
              'required' => true,
              'default' => nil,
              'options' => nil,
              'regex' => nil
            },
            {
              'name' => 'optional_string_input',
              'type' => 'STRING',
              'description' => nil,
              'required' => false,
              'default' => 'default-value',
              'options' => nil,
              'regex' => nil
            },
            {
              'name' => 'optional_number_input',
              'type' => 'NUMBER',
              'description' => nil,
              'required' => false,
              'default' => 1,
              'options' => nil,
              'regex' => nil
            },
            {
              'name' => 'optional_boolean_input',
              'type' => 'BOOLEAN',
              'description' => 'Optional boolean input',
              'required' => false,
              'default' => true,
              'options' => nil,
              'regex' => nil
            },
            {
              'name' => 'optional_array_input',
              'type' => 'ARRAY',
              'description' => nil,
              'required' => false,
              'default' => [{ 'a' => 1 }, { 'b' => 2 }],
              'options' => nil,
              'regex' => nil
            },
            {
              'name' => 'string_input_with_options',
              'type' => 'STRING',
              'description' => nil,
              'required' => true,
              'default' => nil,
              'options' => %w[option1 option2 option3],
              'regex' => nil
            },
            {
              'name' => 'number_input_with_options',
              'type' => 'NUMBER',
              'description' => nil,
              'required' => true,
              'default' => nil,
              'options' => [1, 2, 3],
              'regex' => nil
            },
            {
              'name' => 'string_input_with_regex',
              'type' => 'STRING',
              'description' => nil,
              'required' => true,
              'default' => nil,
              'options' => nil,
              'regex' => '[a-z]+'
            }
          ]
        })
      end
    end

    context 'when input does not exist' do
      let(:ref) { 'feature-no-inputs' }

      it 'returns no inputs' do
        post_graphql(query, current_user: user)

        expect(graphql_data['project'])
          .to eq({ 'ciPipelineCreationInputs' => [] })
      end
    end

    context 'when ref is not found' do
      let(:ref) { 'non-existent-ref' }

      it 'returns an error' do
        post_graphql(query, current_user: user)

        expect(graphql_errors)
          .to include(a_hash_including('message' => 'The branch or tag does not exist'))
      end
    end
  end

  context 'when current user cannot access the project' do
    let(:ref) { 'master' }

    before_all do
      project.add_guest(user)
    end

    it 'returns an error' do
      post_graphql(query, current_user: user)

      expect(graphql_data['project'])
        .to eq('ciPipelineCreationInputs' => nil)
    end
  end
end
