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
      let(:location) { %w(some/file.txt other/file.txt) }

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
          .to eq('`some/file/xxxxxxxxxxxxxxxx.yml`: content does not have a valid YAML syntax')
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

    context 'when interpolation is disabled but there is a spec header' do
      before do
        stub_feature_flags(ci_includable_files_interpolation: false)
      end

      let(:location) { 'some-location.yml' }

      let(:content) do
        <<~YAML
        spec:
          include:
            website:
        ---
        run:
          script: deploy $[[ inputs.website ]]
        YAML
      end

      it 'returns an error saying that interpolation is disabled' do
        expect(valid?).to be_falsy
        expect(file.errors)
          .to include('`some-location.yml`: can not evaluate included file because interpolation is disabled')
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
            .to include('`some-location.yml`: interpolation interrupted by errors, unknown interpolation key: `abcd`')
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

    it {
      is_expected.to eq(
        context_project: project.full_path,
        context_sha: 'HEAD'
      )
    }
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
end
