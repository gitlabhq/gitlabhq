# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/rspec/all'
require_relative '../../../scripts/cells/ci-ensure-application-settings-have-definition-file'

RSpec.describe CiEnsureApplicationSettingsHaveDefinitionFile, feature_category: :tooling do
  let(:attributes) { [] }
  let(:definition_files) { [] }
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  subject(:checker) do
    described_class.new(attributes: attributes, definition_files: definition_files, stdout: stdout, stderr: stderr)
  end

  describe '#execute!' do
    context 'when everything is good' do
      let(:definition_file) { Tempfile.new(['def', '.yml']) }
      let(:definition_files) { [definition_file.path] }
      let(:attribute) do
        instance_double(
          'ApplicationSettingsAnalysis::ApplicationSetting',
          definition_file_exist?: true,
          definition_file_path: definition_file.path
        )
      end

      let(:attributes) { [attribute] }

      it 'does not print an error and nor raise an exception' do
        expect { checker.execute! }.not_to raise_error
      end
    end

    context 'when an attribute does not have a definition file' do
      let(:attribute) { ApplicationSettingsAnalysis::ApplicationSetting.new(column: 'foo') }
      let(:attributes) { [attribute] }

      it 'prints an error and raises an exception' do
        expect(attribute.definition_file_exist?).to eq(false)
        expect(stderr).to receive(:puts).with(
          %r{Attribute `foo` is missing a definition file at `.+config/application_setting_columns/foo.yml`!}
        )
        expect { checker.execute! }.to raise_error(described_class::MISSING_DEFINITION_FILES)
      end
    end

    context 'when a definition file does not have an attribute' do
      let(:definition_file) { Tempfile.new(['def', '.yml']) }
      let(:definition_files) { [definition_file] }

      it 'prints an error and raises an exception' do
        expect(stderr).to receive(:puts).with(
          %r{Definition file `#{definition_file.path}` doesn't have a corresponding attribute!}
        )
        expect { checker.execute! }.to raise_error(described_class::EXTRA_DEFINITION_FILES)
      end
    end
  end
end
