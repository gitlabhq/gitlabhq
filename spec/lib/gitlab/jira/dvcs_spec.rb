# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Jira::Dvcs do
  describe '.encode_slash' do
    it 'replaces slash character' do
      expect(described_class.encode_slash('a/b/c')).to eq('a@b@c')
    end

    it 'ignores path without slash' do
      expect(described_class.encode_slash('foo')).to eq('foo')
    end
  end

  describe '.decode_slash' do
    it 'replaces slash character' do
      expect(described_class.decode_slash('a@b@c')).to eq('a/b/c')
    end

    it 'ignores path without slash' do
      expect(described_class.decode_slash('foo')).to eq('foo')
    end
  end

  describe '.encode_project_name' do
    let(:group) { create(:group) }
    let(:project) { create(:project, group: group) }

    context 'root group' do
      it 'returns project path' do
        expect(described_class.encode_project_name(project)).to eq(project.path)
      end
    end

    context 'nested group' do
      let(:group) { create(:group, :nested) }

      it 'returns encoded project full path' do
        expect(described_class.encode_project_name(project)).to eq(described_class.encode_slash(project.full_path))
      end
    end
  end

  describe '.restore_full_path' do
    context 'project name is an encoded full path' do
      it 'returns decoded project path' do
        expect(described_class.restore_full_path(namespace: 'group1', project: 'group1@group2@project1')).to eq('group1/group2/project1')
      end

      it 'does not return full path starting with slash' do
        expect(described_class.restore_full_path(namespace: 'group1', project: '@group1/project1')).to eq('group1/project1')
      end
    end

    context 'project name is not an encoded full path' do
      it 'assumes project belongs to root namespace and returns full project path based on passed in namespace' do
        expect(described_class.restore_full_path(namespace: 'group1', project: 'project1')).to eq('group1/project1')
      end
    end
  end
end
