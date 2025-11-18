# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DuoAgentPlatform::Config, feature_category: :duo_agent_platform do
  let_it_be(:project) { create(:project, :repository) }

  let(:config) { described_class.new(project) }
  let(:config_path) { '.gitlab/duo/agent-config.yml' }
  let(:default_branch) { 'main' }
  let(:commit_sha) { 'abc123' }

  before do
    allow(project).to receive(:default_branch).and_return(default_branch)
    commit = Struct.new(:sha).new(commit_sha)
    allow(project.repository).to receive(:commit).with(default_branch).and_return(commit)
  end

  describe '#default_image' do
    context 'when config contains an image' do
      before do
        allow(project.repository).to receive(:blob_data_at)
                                       .with(default_branch, config_path)
                                       .and_return("image: ruby:3.0\nother: value")
      end

      it 'returns the image value' do
        expect(config.default_image).to eq('ruby:3.0')
      end
    end

    context 'when config file does not exist' do
      before do
        allow(project.repository).to receive(:blob_data_at)
                                       .with(default_branch, config_path)
                                       .and_return(nil)
      end

      it 'returns nil' do
        expect(config.default_image).to be_nil
      end
    end

    context 'when config does not contain an image key' do
      before do
        allow(project.repository).to receive(:blob_data_at)
                                       .with(default_branch, config_path)
                                       .and_return("other_key: value")
      end

      it 'returns nil' do
        expect(config.default_image).to be_nil
      end
    end
  end

  describe '#setup_script' do
    context 'when config contains setup_script as array' do
      let(:config_content) do
        <<~YAML
          setup_script:
            - npm install
            - npm run build
            - echo "Setup complete"
        YAML
      end

      before do
        allow(project.repository).to receive(:blob_data_at)
                                       .with(default_branch, config_path)
                                       .and_return(config_content)
      end

      it 'returns array of commands' do
        expect(config.setup_script).to match_array(['npm install', 'npm run build', 'echo "Setup complete"'])
      end
    end

    context 'when config contains setup_script as single string' do
      let(:config_content) do
        <<~YAML
          setup_script: npm install
        YAML
      end

      before do
        allow(project.repository).to receive(:blob_data_at)
                                       .with(default_branch, config_path)
                                       .and_return(config_content)
      end

      it 'returns array with single command' do
        expect(config.setup_script).to eq(['npm install'])
      end
    end

    context 'when config does not contain setup_script' do
      let(:config_content) do
        <<~YAML
          image: node:18-alpine
          other_key: value
        YAML
      end

      before do
        allow(project.repository).to receive(:blob_data_at)
                                       .with(default_branch, config_path)
                                       .and_return(config_content)
      end

      it 'returns nil' do
        expect(config.setup_script).to be_nil
      end
    end

    context 'when config file does not exist' do
      before do
        allow(project.repository).to receive(:blob_data_at)
                                       .with(default_branch, config_path)
                                       .and_return(nil)
      end

      it 'returns nil' do
        expect(config.setup_script).to be_nil
      end
    end
  end

  describe '#cache_config' do
    context 'with file-based cache key' do
      let(:config_content) do
        <<~YAML
          cache:
            key:
              files:
                - package.json
                - package-lock.json
            paths:
              - node_modules
              - .npm
        YAML
      end

      before do
        allow(project.repository).to receive(:blob_data_at)
                                       .with(default_branch, config_path)
                                       .and_return(config_content)
      end

      it 'returns normalized cache configuration' do
        expected = {
          'key' => {
            'files' => ['package.json', 'package-lock.json']
          },
          'paths' => ['node_modules', '.npm']
        }
        expect(config.cache_config).to eq(expected)
      end
    end

    context 'with file-based key and prefix' do
      let(:config_content) do
        <<~YAML
          cache:
            key:
              files:
                - Gemfile.lock
              prefix: rspec
            paths:
              - vendor/ruby
        YAML
      end

      before do
        allow(project.repository).to receive(:blob_data_at)
                                       .with(default_branch, config_path)
                                       .and_return(config_content)
      end

      it 'returns cache configuration with prefix' do
        expected = {
          'key' => {
            'files' => ['Gemfile.lock'],
            'prefix' => 'rspec'
          },
          'paths' => ['vendor/ruby']
        }
        expect(config.cache_config).to eq(expected)
      end
    end

    context 'with more than two files in cache key' do
      let(:config_content) do
        <<~YAML
          cache:
            key:
              files:
                - file1.txt
                - file2.txt
                - file3.txt
                - file4.txt
            paths:
              - node_modules
        YAML
      end

      before do
        allow(project.repository).to receive(:blob_data_at)
                                       .with(default_branch, config_path)
                                       .and_return(config_content)
      end

      it 'only uses first two files' do
        expected = {
          'key' => {
            'files' => ['file1.txt', 'file2.txt']
          },
          'paths' => ['node_modules']
        }
        expect(config.cache_config).to eq(expected)
      end
    end

    context 'with string cache key' do
      let(:config_content) do
        <<~YAML
          cache:
            key: my-cache-key
            paths:
              - node_modules
        YAML
      end

      before do
        allow(project.repository).to receive(:blob_data_at)
                                       .with(default_branch, config_path)
                                       .and_return(config_content)
      end

      it 'returns cache configuration with string key' do
        expected = {
          'key' => 'my-cache-key',
          'paths' => ['node_modules']
        }
        expect(config.cache_config).to eq(expected)
      end
    end

    context 'with only paths (no key)' do
      let(:config_content) do
        <<~YAML
          cache:
            paths:
              - node_modules
              - vendor/bundle
        YAML
      end

      before do
        allow(project.repository).to receive(:blob_data_at)
                                       .with(default_branch, config_path)
                                       .and_return(config_content)
      end

      it 'returns cache configuration without key' do
        expected = {
          'paths' => ['node_modules', 'vendor/bundle']
        }
        expect(config.cache_config).to eq(expected)
      end
    end

    context 'without paths (invalid cache)' do
      let(:config_content) do
        <<~YAML
          cache:
            key: my-cache-key
        YAML
      end

      before do
        allow(project.repository).to receive(:blob_data_at)
                                       .with(default_branch, config_path)
                                       .and_return(config_content)
      end

      it 'returns nil since paths are required' do
        expect(config.cache_config).to be_nil
      end
    end

    context 'when cache is not a hash' do
      let(:config_content) do
        <<~YAML
          cache: invalid
        YAML
      end

      before do
        allow(project.repository).to receive(:blob_data_at)
                                       .with(default_branch, config_path)
                                       .and_return(config_content)
      end

      it 'returns nil' do
        expect(config.cache_config).to be_nil
      end
    end

    context 'when config does not contain cache' do
      let(:config_content) do
        <<~YAML
          image: node:18-alpine
          setup_script:
            - npm install
        YAML
      end

      before do
        allow(project.repository).to receive(:blob_data_at)
                                       .with(default_branch, config_path)
                                       .and_return(config_content)
      end

      it 'returns nil' do
        expect(config.cache_config).to be_nil
      end
    end

    context 'when config file does not exist' do
      before do
        allow(project.repository).to receive(:blob_data_at)
                                       .with(default_branch, config_path)
                                       .and_return(nil)
      end

      it 'returns nil' do
        expect(config.cache_config).to be_nil
      end
    end

    context 'with file-based key but no files' do
      let(:config_content) do
        <<~YAML
          cache:
            key:
              prefix: test
            paths:
              - node_modules
        YAML
      end

      before do
        allow(project.repository).to receive(:blob_data_at)
                                       .with(default_branch, config_path)
                                       .and_return(config_content)
      end

      it 'returns cache configuration without key since files are missing' do
        expected = {
          'paths' => ['node_modules']
        }
        expect(config.cache_config).to eq(expected)
      end
    end

    context 'with paths as single string' do
      let(:config_content) do
        <<~YAML
          cache:
            paths: node_modules
        YAML
      end

      before do
        allow(project.repository).to receive(:blob_data_at)
                                       .with(default_branch, config_path)
                                       .and_return(config_content)
      end

      it 'converts single path to array' do
        expected = {
          'paths' => ['node_modules']
        }
        expect(config.cache_config).to eq(expected)
      end
    end

    context 'with empty paths array' do
      let(:config_content) do
        <<~YAML
          cache:
            key: test-key
            paths: []
        YAML
      end

      before do
        allow(project.repository).to receive(:blob_data_at)
                                       .with(default_branch, config_path)
                                       .and_return(config_content)
      end

      it 'returns nil since paths are empty' do
        expect(config.cache_config).to be_nil
      end
    end
  end

  describe '#valid?' do
    context 'with valid YAML hash' do
      before do
        allow(project.repository).to receive(:blob_data_at)
                                       .with(default_branch, config_path)
                                       .and_return("key: value")
      end

      it 'returns true' do
        expect(config.valid?).to be true
      end
    end

    context 'with empty file' do
      before do
        allow(project.repository).to receive(:blob_data_at)
                                       .with(default_branch, config_path)
                                       .and_return(nil)
      end

      it 'returns false' do
        expect(config.valid?).to be false
      end
    end

    context 'when YAML parsing fails' do
      before do
        # Unmatched bracket will cause syntax error
        allow(project.repository).to receive(:blob_data_at)
                                       .with(default_branch, config_path)
                                       .and_return("[")

        # Ensure cache yields to the block to trigger the parsing
        allow(Rails.cache).to receive(:fetch).and_yield
      end

      it 'returns false and tracks the error' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
                                           .with(instance_of(Psych::SyntaxError), project_id: project.id)

        expect(config.valid?).to be false
      end
    end

    context 'with complex valid configuration' do
      let(:config_content) do
        <<~YAML
          image: node:18-alpine
          setup_script:
            - npm ci
            - npm test
          cache:
            key:
              files:
                - package.json
                - package-lock.json
              prefix: test
            paths:
              - node_modules
              - .npm
        YAML
      end

      before do
        allow(project.repository).to receive(:blob_data_at)
                                       .with(default_branch, config_path)
                                       .and_return(config_content)
      end

      it 'returns true' do
        expect(config.valid?).to be true
      end

      it 'correctly parses all configuration sections' do
        expect(config.default_image).to eq('node:18-alpine')
        expect(config.setup_script).to match_array(['npm ci', 'npm test'])
        expect(config.cache_config).to eq({
          'key' => {
            'files' => ['package.json', 'package-lock.json'],
            'prefix' => 'test'
          },
          'paths' => ['node_modules', '.npm']
        })
      end
    end
  end

  describe 'caching' do
    let(:cache_key) { "duo_config:#{project.id}:#{commit_sha}" }

    before do
      allow(project.repository).to receive(:blob_data_at)
                                     .with(default_branch, config_path)
                                     .and_return("image: cached-image")
    end

    it 'uses Rails cache with correct key and expiry' do
      expect(Rails.cache).to receive(:fetch)
                               .with(cache_key, expires_in: 5.minutes)
                               .and_call_original

      config
    end

    context 'when commit SHA is nil' do
      before do
        allow(project.repository).to receive(:commit).with(default_branch).and_return(nil)
      end

      it 'uses "empty" in cache key' do
        expect(Rails.cache).to receive(:fetch)
                                 .with("duo_config:#{project.id}:empty", expires_in: 5.minutes)
                                 .and_call_original

        config
      end
    end

    context 'with multiple method calls' do
      let(:config_content) do
        <<~YAML
          image: ruby:3.0
          setup_script:
            - bundle install
          cache:
            paths:
              - vendor/bundle
        YAML
      end

      before do
        allow(project.repository).to receive(:blob_data_at)
                                       .with(default_branch, config_path)
                                       .and_return(config_content)
      end

      it 'uses the same cached configuration for all methods' do
        expect(Rails.cache).to receive(:fetch)
                                 .with(cache_key, expires_in: 5.minutes)
                                 .once
                                 .and_call_original

        expect(config.default_image).to eq('ruby:3.0')
        expect(config.setup_script).to eq(['bundle install'])
        expect(config.cache_config).to eq({ 'paths' => ['vendor/bundle'] })
      end
    end
  end
end
