# frozen_string_literal: true

# Shared examples for External::Mapper::Matcher and Header::Mapper::Matcher
#
# These examples test common behavior across both matcher types.
# The including spec must define:
#   - matcher: instance of the matcher being tested
#   - context: the external context
#   - supported_file_types: hash mapping location types to expected file classes
#
RSpec.shared_examples 'processes supported file types' do
  context 'when processing supported file types' do
    let(:locations) { supported_file_types.keys }

    it 'returns correct file objects for each type' do
      result = matcher.process(locations)

      supported_file_types.each_value do |file_class|
        expect(result).to include(an_instance_of(file_class))
      end
    end
  end
end

RSpec.shared_examples 'handles invalid locations' do
  context 'when a location is not valid' do
    let(:locations) { [{ invalid: 'file.yml' }] }

    it 'raises an ambiguous specification error' do
      expect { matcher.process(locations) }.to raise_error(
        Gitlab::Ci::Config::External::Mapper::AmbigiousSpecificationError,
        /does not have a valid subkey for.*include/
      )
    end
  end
end

RSpec.shared_examples 'handles ambiguous locations' do
  context 'when a location is ambiguous' do
    let(:locations) { [{ local: 'file.yml', remote: 'https://example.com/.gitlab-ci.yml' }] }

    it 'raises an ambiguous specification error' do
      expect { matcher.process(locations) }.to raise_error(
        Gitlab::Ci::Config::External::Mapper::AmbigiousSpecificationError,
        /Each include must use only one of:/
      )
    end
  end
end

RSpec.shared_examples 'masks variables in error messages' do
  context 'when the invalid location includes a masked variable' do
    let(:locations) { [{ invalid: masked_variable_value }] }

    it 'raises an error with a masked sentence' do
      expect { matcher.process(locations) }.to raise_error(
        Gitlab::Ci::Config::External::Mapper::AmbigiousSpecificationError,
        /\[MASKED\]/
      )
    end
  end
end
