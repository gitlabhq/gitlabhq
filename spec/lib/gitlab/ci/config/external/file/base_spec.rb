# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::File::Base, feature_category: :pipeline_composition do
  let(:variables) {}
  let(:context_params) { { sha: 'HEAD', variables: variables } }
  let(:context) { Gitlab::Ci::Config::External::Context.new(**context_params) }

  let(:test_class) do
    Class.new(described_class) do
      def initialize(params, context)
        @location = params

        super
      end

      def validate_context!
        # no-op
      end
    end
  end

  subject(:file) { test_class.new(location, context) }

  before do
    allow_any_instance_of(test_class)
      .to receive(:content).and_return('key: value')

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
      Gitlab::Ci::Config::External::Mapper::Verifier.new(context).process([file])
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
      let(:variables) { Gitlab::Ci::Variables::Collection.new([{ 'key' => 'GITLAB_TOKEN', 'value' => 'secret_file_name', 'masked' => true }]) }

      before do
        allow_any_instance_of(test_class)
          .to receive(:content).and_return('invalid_syntax')
      end

      it 'is not a valid file' do
        expect(valid?).to be_falsy
        expect(file.error_message).to eq('Included file `some/file/xxxxxxxxxxxxxxxx.yml` does not have valid YAML syntax!')
      end
    end

    context 'when the class has no validate_context!' do
      let(:test_class) do
        Class.new(described_class) do
          def initialize(params, context)
            @location = params

            super
          end
        end
      end

      let(:location) { 'some/file/config.yaml' }

      it 'raises an error' do
        expect { valid? }.to raise_error(NotImplementedError)
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
        context_project: nil,
        context_sha: 'HEAD'
      )
    }
  end

  describe '#eql?' do
    let(:location) { 'some/file/config.yml' }

    subject(:eql) { file.eql?(other_file) }

    context 'when the other file has the same params' do
      let(:other_file) { test_class.new(location, context) }

      it { is_expected.to eq(true) }
    end

    context 'when the other file has not the same params' do
      let(:other_file) { test_class.new('some/other/file', context) }

      it { is_expected.to eq(false) }
    end
  end

  describe '#hash' do
    let(:location) { 'some/file/config.yml' }

    subject(:filehash) { file.hash }

    context 'with a project' do
      let(:project) { create(:project) }
      let(:context_params) { { project: project, sha: 'HEAD', variables: variables } }

      it { is_expected.to eq([location, project.full_path, 'HEAD'].hash) }
    end

    context 'without a project' do
      it { is_expected.to eq([location, nil, 'HEAD'].hash) }
    end
  end
end
