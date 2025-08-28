# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DuoAgentPlatform::Config, feature_category: :agent_foundations do
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
  end

  describe 'caching' do
    let(:cache_key) { "duo_config:default_image:#{project.id}:#{commit_sha}" }

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
                                 .with("duo_config:default_image:#{project.id}:empty", expires_in: 5.minutes)
                                 .and_call_original

        config
      end
    end
  end
end
