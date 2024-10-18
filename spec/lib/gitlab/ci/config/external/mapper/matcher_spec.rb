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
    subject(:process) { matcher.process(locations) }

    let(:locations) do
      [
        { local: 'file.yml' },
        { file: 'file.yml', project: 'namespace/project' },
        { component: 'gitlab.com/org/component@1.0' },
        { remote: 'https://example.com/.gitlab-ci.yml' },
        { template: 'file.yml' },
        { artifact: 'generated.yml', job: 'test' }
      ]
    end

    it 'returns an array of file objects' do
      is_expected.to contain_exactly(
        an_instance_of(Gitlab::Ci::Config::External::File::Local),
        an_instance_of(Gitlab::Ci::Config::External::File::Project),
        an_instance_of(Gitlab::Ci::Config::External::File::Component),
        an_instance_of(Gitlab::Ci::Config::External::File::Remote),
        an_instance_of(Gitlab::Ci::Config::External::File::Template),
        an_instance_of(Gitlab::Ci::Config::External::File::Artifact)
      )
    end

    context 'when a location is not valid' do
      let(:locations) { [{ invalid: 'file.yml' }] }

      it 'raises an error' do
        expect { process }.to raise_error(
          Gitlab::Ci::Config::External::Mapper::AmbigiousSpecificationError,
          /`{"invalid":"file.yml"}` does not have a valid subkey for include. Valid subkeys are:/
        )
      end

      context 'when the invalid location includes a masked variable' do
        let(:locations) { [{ invalid: 'this-is-secret.yml' }] }

        it 'raises an error with a masked sentence' do
          expect { process }.to raise_error(
            Gitlab::Ci::Config::External::Mapper::AmbigiousSpecificationError,
            /`{"invalid":"\[MASKED\]xxxxxx.yml"}` does not have a valid subkey for include. Valid subkeys are:/
          )
        end
      end
    end

    context 'when a location is ambiguous' do
      let(:locations) { [{ local: 'file.yml', remote: 'https://example.com/.gitlab-ci.yml' }] }

      it 'raises an error' do
        expect { process }.to raise_error(
          Gitlab::Ci::Config::External::Mapper::AmbigiousSpecificationError,
          /Each include must use only one of:/
        )
      end
    end
  end
end
