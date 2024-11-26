# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::File::Base, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project) }
  let(:variables) {}
  let(:context_params) { { sha: 'HEAD', variables: variables, project: project } }
  let(:ctx) { Gitlab::Ci::Config::External::Context.new(**context_params) }

  let(:test_class) do
    Class.new(described_class) do
      def initialize(params, ctx)
        @location = params[:location]

        super
      end

      def validate_context!
        # no-op
      end

      def content
        params[:content]
      end
    end
  end

  let(:content) { 'key: value' }

  subject(:file) { test_class.new({ location: location, content: content }, ctx) }

  before do
    allow_any_instance_of(Gitlab::Ci::Config::External::Context)
      .to receive(:check_execution_time!)
  end

  describe '#matching?' do
    context 'when a location is present' do
      let(:location) { 'some-location' }

      it 'returns true' do
        expect(file).to be_matching
      end
    end

    context 'with a location is missing' do
      let(:location) { nil }

      it 'returns false' do
        expect(file).not_to be_matching
      end
    end
  end

  describe '#valid?' do
    subject(:valid?) do
      Gitlab::Ci::Config::External::Mapper::Verifier.new(ctx).process([file])
      file.valid?
    end

    context 'when location is not a string' do
      let(:location) { %w[some/file.txt other/file.txt] }

      it { is_expected.to be_falsy }
    end

    context 'when location is not a YAML file' do
      let(:location) { 'some/file.txt' }

      it { is_expected.to be_falsy }
    end

    context 'when location has not a valid naming scheme' do
      let(:location) { 'some/file/.yml' }

      it { is_expected.to be_falsy }
    end

    context 'when location is a valid .yml extension' do
      let(:location) { 'some/file/config.yml' }

      it { is_expected.to be_truthy }
    end

    context 'when location is a valid .yaml extension' do
      let(:location) { 'some/file/config.yaml' }

      it { is_expected.to be_truthy }
    end

    context 'when there are YAML syntax errors' do
      let(:location) { 'some/file/secret_file_name.yml' }

      let(:variables) do
        Gitlab::Ci::Variables::Collection.new(
          [{ 'key' => 'GITLAB_TOKEN', 'value' => 'secret_file_name', 'masked' => true }]
        )
      end

      before do
        allow_any_instance_of(test_class)
          .to receive(:content).and_return('invalid_syntax')
      end

      it 'is not a valid file' do
        expect(valid?).to be_falsy
        expect(file.error_message)
          .to eq('`some/file/[MASKED]xxxxxxxx.yml`: Invalid configuration format')
      end
    end

    context 'when the class has no validate_context!' do
      let(:test_class) do
        Class.new(described_class) do
          def initialize(params, ctx)
            @location = params[:location]

            super
          end
        end
      end

      let(:location) { 'some/file/config.yaml' }

      it 'raises an error' do
        expect { valid? }.to raise_error(NotImplementedError)
      end
    end

    context 'when interpolation was unsuccessful' do
      let(:location) { 'some-location.yml' }

      context 'when context key is missing' do
        let(:content) do
          <<~YAML
            spec:
              inputs:
            ---
            run:
              script: deploy $[[ inputs.abcd ]]
          YAML
        end

        it 'surfaces interpolation errors' do
          expect(valid?).to be_falsy
          expect(file.errors)
            .to include('`some-location.yml`: unknown interpolation key: `abcd`')
        end
      end

      context 'when header is invalid' do
        let(:content) do
          <<~YAML
            spec:
              a: abc
            ---
            run:
              script: deploy $[[ inputs.abcd ]]
          YAML
        end

        it 'surfaces header errors' do
          expect(valid?).to be_falsy
          expect(file.errors)
            .to include('`some-location.yml`: header:spec config contains unknown keys: a')
        end
      end

      context 'when header is not a hash' do
        let(:content) do
          <<~YAML
            spec: abcd
            ---
            run:
              script: deploy $[[ inputs.abcd ]]
          YAML
        end

        it 'surfaces header errors' do
          expect(valid?).to be_falsy
          expect(file.errors)
            .to contain_exactly('`some-location.yml`: header:spec config should be a hash')
        end
      end
    end
  end

  describe '#to_hash' do
    context 'with includes' do
      let(:location) { 'some/file/config.yml' }
      let(:content) { 'include: { template: Bash.gitlab-ci.yml }' }

      before do
        allow_any_instance_of(test_class)
          .to receive(:content).and_return(content)
      end

      it 'does expand hash to include the template' do
        expect(file.to_hash).to include(:before_script)
      end
    end
  end

  describe '#metadata' do
    let(:location) { 'some/file/config.yml' }

    subject(:metadata) { file.metadata }

    it do
      is_expected.to eq(
        context_project: project.full_path,
        context_sha: 'HEAD'
      )
    end
  end

  describe '#eql?' do
    let(:location) { 'some/file/config.yml' }

    subject(:eql) { file.eql?(other_file) }

    context 'when the other file has the same params' do
      let(:other_file) { test_class.new({ location: location, content: content }, ctx) }

      it { is_expected.to eq(true) }
    end

    context 'when the other file has not the same params' do
      let(:other_file) { test_class.new({ location: 'some/other/file', content: content }, ctx) }

      it { is_expected.to eq(false) }
    end
  end

  describe '#hash' do
    let(:location) { 'some/file/config.yml' }

    subject(:filehash) { file.hash }

    context 'with a project' do
      let(:context_params) { { project: project, sha: 'HEAD', variables: variables } }

      it { is_expected.to eq([{ location: location, content: content }, project.full_path, 'HEAD'].hash) }
    end

    context 'without a project' do
      let(:context_params) { { sha: 'HEAD', variables: variables } }

      it { is_expected.to eq([{ location: location, content: content }, nil, 'HEAD'].hash) }
    end
  end

  describe '#load_and_validate_expanded_hash!' do
    let(:location) { 'some/file/config.yml' }
    let(:logger) { instance_double(::Gitlab::Ci::Pipeline::Logger, :instrument) }
    let(:context_params) { { sha: 'HEAD', variables: variables, project: project, logger: logger, user: user } }
    let(:user) { instance_double(User, id: 'test-user-id') }

    before do
      allow(logger).to receive(:instrument).and_yield
    end

    it 'includes instrumentation for loading and expanding the content' do
      expect(logger).to receive(:instrument).once.ordered.with(:config_file_fetch_content_hash).and_yield
      expect(logger).to receive(:instrument).once.ordered.with(:config_file_expand_content_includes).and_yield

      file.load_and_validate_expanded_hash!
    end

    context 'when the content is interpolated' do
      let(:content) { "spec:\n  inputs:\n    website:\n---\nkey: value" }

      subject(:file) { test_class.new({ inputs: { website: 'test' }, location: location, content: content }, ctx) }

      it 'increments the ci_interpolation_users usage counter' do
        expect(::Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event)
          .with('ci_interpolation_users', values: 'test-user-id')

        file.load_and_validate_expanded_hash!
      end
    end

    context 'when the content is not interpolated' do
      it 'does not increment the ci_interpolation_users usage counter' do
        expect(::Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

        file.load_and_validate_expanded_hash!
      end
    end
  end
end
