# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Lint::ResultEntity do
  describe '#represent' do
    let(:yaml_content) { YAML.dump({ rspec: { script: 'test', tags: 'mysql' } }) }
    let(:result) { Gitlab::Ci::YamlProcessor.new(yaml_content).execute }

    subject(:serialized_linting_result) { described_class.new(result).as_json }

    it 'serializes with lint result entity' do
      expect(serialized_linting_result.keys).to include(:valid, :errors, :jobs, :warnings)
    end
  end
end
