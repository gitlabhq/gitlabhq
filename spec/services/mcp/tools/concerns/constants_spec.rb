# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Concerns::Constants, feature_category: :mcp_server do
  let(:test_class) do
    Class.new do
      include Mcp::Tools::Concerns::Constants
    end
  end

  describe 'GROUP_ONLY_TYPES' do
    it 'contains work item types that can only exist in groups' do
      expect(test_class::GROUP_ONLY_TYPES).to eq(%w[Epic Objective KeyResult])
    end

    it 'is frozen' do
      expect(test_class::GROUP_ONLY_TYPES).to be_frozen
    end
  end

  describe 'PROJECT_AND_GROUP_TYPES' do
    it 'contains work item types that can exist in both projects and groups' do
      expect(test_class::PROJECT_AND_GROUP_TYPES).to eq(%w[Issue Task])
    end

    it 'is frozen' do
      expect(test_class::PROJECT_AND_GROUP_TYPES).to be_frozen
    end
  end

  describe 'ALL_TYPES' do
    it 'contains all work item types' do
      expect(test_class::ALL_TYPES).to match_array(%w[Issue Task Epic Objective KeyResult])
    end

    it 'combines PROJECT_AND_GROUP_TYPES and GROUP_ONLY_TYPES' do
      expected = test_class::PROJECT_AND_GROUP_TYPES + test_class::GROUP_ONLY_TYPES
      expect(test_class::ALL_TYPES).to eq(expected)
    end

    it 'is frozen' do
      expect(test_class::ALL_TYPES).to be_frozen
    end
  end

  describe 'URL_PATTERNS' do
    describe ':work_item pattern' do
      let(:pattern) { test_class::URL_PATTERNS[:work_item] }

      it 'matches project work item URLs' do
        match = 'namespace/project/-/work_items/42'.match(pattern)
        expect(match).not_to be_nil
        expect(match[:path]).to eq('namespace/project')
        expect(match[:id]).to eq('42')
      end

      it 'matches group work item URLs' do
        match = 'groups/namespace/group/-/work_items/123'.match(pattern)
        expect(match).not_to be_nil
        expect(match[:path]).to eq('namespace/group')
        expect(match[:id]).to eq('123')
      end

      it 'matches nested group work item URLs' do
        match = 'groups/parent/child/grandchild/-/work_items/999'.match(pattern)
        expect(match).not_to be_nil
        expect(match[:path]).to eq('parent/child/grandchild')
        expect(match[:id]).to eq('999')
      end

      it 'matches URLs with leading slash' do
        match = '/namespace/project/-/work_items/42'.match(pattern)
        expect(match).not_to be_nil
        expect(match[:path]).to eq('namespace/project')
        expect(match[:id]).to eq('42')
      end

      it 'does not match invalid URLs' do
        expect('invalid/url'.match(pattern)).to be_nil
        expect('namespace/project/work_items/42'.match(pattern)).to be_nil
        expect('namespace/project/-/issues/42'.match(pattern)).to be_nil
        expect('namespace/project/-/work_items/42/extra'.match(pattern)).to be_nil
        expect('namespace with space/project/-/work_items/42'.match(pattern)).to be_nil
      end
    end

    describe ':quick_action pattern' do
      let(:pattern) { test_class::URL_PATTERNS[:quick_action] }

      it 'matches quick actions at the start of a line' do
        expect('/merge'.match(pattern)).not_to be_nil
        expect('/approve'.match(pattern)).not_to be_nil
        expect('/close'.match(pattern)).not_to be_nil
        expect('/assign'.match(pattern)).not_to be_nil
      end

      it 'matches quick actions with leading whitespace' do
        expect('  /merge'.match(pattern)).not_to be_nil
        expect("\t/approve".match(pattern)).not_to be_nil
        expect("\n/close".match(pattern)).not_to be_nil
      end

      it 'does not match quick actions in the middle of text' do
        expect('This is /merge text'.match(pattern)).to be_nil
        expect('Some text /approve here'.match(pattern)).to be_nil
      end

      it 'matches quick actions in multiline text' do
        text = "Some description\n/assign @user\nMore text"
        expect(text.match(pattern)).not_to be_nil
      end
    end

    it 'is frozen' do
      expect(test_class::URL_PATTERNS).to be_frozen
    end
  end

  describe 'VERSIONS' do
    it 'defines version 0.1.0' do
      expect(test_class::VERSIONS[:v0_1_0]).to eq('0.1.0')
    end

    it 'is frozen' do
      expect(test_class::VERSIONS).to be_frozen
    end

    it 'all version values follow semantic versioning pattern' do
      version_pattern = /\A\d+\.\d+\.\d+\z/

      test_class::VERSIONS.each_value do |version|
        expect(version).to match(version_pattern),
          "Expected version '#{version}' to match semantic versioning pattern (e.g., '1.2.3')"
      end
    end
  end
end
