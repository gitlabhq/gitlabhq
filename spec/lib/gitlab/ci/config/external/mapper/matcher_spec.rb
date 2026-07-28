# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::Mapper::Matcher, feature_category: :pipeline_composition do
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

    # External supports all file types
    let(:supported_file_types) do
      {
        { local: 'file.yml' } => Gitlab::Ci::Config::External::File::Local,
        { file: 'file.yml', project: 'namespace/project' } => Gitlab::Ci::Config::External::File::Project,
        { component: 'gitlab.com/org/component@1.0' } => Gitlab::Ci::Config::External::File::Component,
        { remote: 'https://example.com/.gitlab-ci.yml' } => Gitlab::Ci::Config::External::File::Remote,
        { template: 'file.yml' } => Gitlab::Ci::Config::External::File::Template,
        { artifact: 'generated.yml', job: 'test' } => Gitlab::Ci::Config::External::File::Artifact
      }
    end

    # Use shared examples
    it_behaves_like 'processes supported file types'
    it_behaves_like 'handles invalid locations'
    it_behaves_like 'handles ambiguous locations'
    it_behaves_like 'masks variables in error messages'

    describe 'forbidden include type' do
      let(:local_location) { { local: 'file.yml' } }
      let(:remote_location) { { remote: 'https://example.com/.gitlab-ci.yml' } }

      context 'when the context restricts allowed include types' do
        let(:context) do
          Gitlab::Ci::Config::External::Context.new(allowed_include_types: %i[local])
        end

        it 'returns the file for an allowed type' do
          expect(matcher.process([local_location]))
            .to contain_exactly(an_instance_of(Gitlab::Ci::Config::External::File::Local))
        end

        it 'raises ForbiddenIncludeTypeError for a disallowed type' do
          expect { matcher.process([remote_location]) }.to raise_error(
            Gitlab::Ci::Config::External::Mapper::ForbiddenIncludeTypeError,
            /`remote` includes are not allowed/
          )
        end
      end

      context 'when the context does not restrict include types' do
        let(:context) { Gitlab::Ci::Config::External::Context.new }

        it 'allows any supported type' do
          expect(matcher.process([remote_location]))
            .to contain_exactly(an_instance_of(Gitlab::Ci::Config::External::File::Remote))
        end
      end
    end
  end
end
