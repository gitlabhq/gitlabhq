# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::VersionHelper, feature_category: :mcp_server do
  let(:test_class) do
    Class.new do
      include Mcp::Tools::VersionHelper
    end
  end

  let(:instance) { test_class.new }

  describe '#validate_semantic_version' do
    context 'with valid semantic versions' do
      it 'returns true for basic semantic versions' do
        expect(instance.validate_semantic_version('1.0.0')).to be true
        expect(instance.validate_semantic_version('0.1.0')).to be true
        expect(instance.validate_semantic_version('10.20.30')).to be true
      end

      it 'returns true for pre-release versions' do
        expect(instance.validate_semantic_version('1.0.0-alpha')).to be true
        expect(instance.validate_semantic_version('1.0.0-beta.1')).to be true
        expect(instance.validate_semantic_version('1.0.0-rc.1')).to be true
      end

      it 'returns true for build metadata' do
        expect(instance.validate_semantic_version('1.0.0+build.1')).to be true
        expect(instance.validate_semantic_version('1.0.0-alpha+build.1')).to be true
      end
    end

    context 'with invalid semantic versions' do
      it 'returns false for invalid formats' do
        expect(instance.validate_semantic_version('1.0')).to be false
        expect(instance.validate_semantic_version('1')).to be false
        expect(instance.validate_semantic_version('v1.0.0')).to be false
        expect(instance.validate_semantic_version('1.0.0.0')).to be false
        expect(instance.validate_semantic_version('invalid-version')).to be false
      end

      it 'returns false for nil or empty values' do
        expect(instance.validate_semantic_version(nil)).to be false
        expect(instance.validate_semantic_version('')).to be false
      end
    end
  end
end
