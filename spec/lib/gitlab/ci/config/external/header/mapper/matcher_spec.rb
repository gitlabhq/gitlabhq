# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::Header::Mapper::Matcher, feature_category: :pipeline_composition do
  let_it_be(:variables) do
    Gitlab::Ci::Variables::Collection.new.tap do |variables|
      variables.append(key: 'A_MASKED_VAR', value: 'this-is-secret', masked: true)
    end
  end

  let_it_be(:context) do
    Gitlab::Ci::Config::External::Context.new(variables: variables)
  end

  subject(:matcher) { described_class.new(context) }

  describe '#process' do
    let(:masked_variable_value) { 'this-is-secret.yml' }

    # Header only supports local, remote, and project includes
    let(:supported_file_types) do
      {
        { local: 'file.yml' } => Gitlab::Ci::Config::External::File::Local,
        { file: 'file.yml', project: 'namespace/project' } => Gitlab::Ci::Config::External::File::Project,
        { remote: 'https://example.com/.gitlab-ci.yml' } => Gitlab::Ci::Config::External::File::Remote
      }
    end

    # Use shared examples
    it_behaves_like 'processes supported file types'
    it_behaves_like 'handles invalid locations'
    it_behaves_like 'handles ambiguous locations'
    it_behaves_like 'masks variables in error messages'

    # Header::Mapper::Matcher specific tests
    context 'when using unsupported file types for header includes' do
      context 'with template include' do
        let(:locations) { [{ template: 'Auto-DevOps.gitlab-ci.yml' }] }

        it 'raises an ambiguous specification error' do
          expect { matcher.process(locations) }.to raise_error(
            Gitlab::Ci::Config::External::Mapper::AmbigiousSpecificationError,
            /does not have a valid subkey for header include/
          )
        end
      end

      context 'with component include' do
        let(:locations) { [{ component: 'gitlab.com/org/component@1.0' }] }

        it 'raises an ambiguous specification error' do
          expect { matcher.process(locations) }.to raise_error(
            Gitlab::Ci::Config::External::Mapper::AmbigiousSpecificationError,
            /does not have a valid subkey for header include/
          )
        end
      end

      context 'with artifact include' do
        let(:locations) { [{ artifact: 'generated.yml', job: 'test' }] }

        it 'raises an ambiguous specification error' do
          expect { matcher.process(locations) }.to raise_error(
            Gitlab::Ci::Config::External::Mapper::AmbigiousSpecificationError,
            /does not have a valid subkey for header include/
          )
        end
      end
    end

    context 'when files are returned' do
      let(:locations) { [{ local: 'inputs.yml' }] }

      it 'returns files with inputs_only mode enabled' do
        files = matcher.process(locations)
        expect(files).to all(be_a(Gitlab::Ci::Config::External::File::Base))
        expect(files.first).to be_inputs_only
      end
    end
  end
end
