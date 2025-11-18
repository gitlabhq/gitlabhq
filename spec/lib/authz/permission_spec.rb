# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::Permission, feature_category: :permissions do
  let(:source_file) { 'config/authz/permissions/permission/test.yml' }
  let(:name) { 'test_permission' }
  let(:action) { nil }
  let(:resource) { nil }
  let(:boundaries) { %w[project] }
  let(:definition) do
    {
      name: name,
      description: 'Test permission description',
      feature_category: 'team_planning',
      action: action,
      resource: resource,
      boundaries: boundaries,
      available_for_tokens: true
    }
  end

  subject(:permission) { described_class.new(definition, source_file) }

  it_behaves_like 'loadable yaml permission or permission group' do
    let(:definition_name) { :create_issue }
    let(:definition) { super() }
  end

  describe '.all_for_tokens' do
    subject(:all_for_tokens) { described_class.all_for_tokens }

    it 'loads all permission definitions available for tokens' do
      expect(all_for_tokens).to be_a(Array)
      expect(all_for_tokens).not_to be_empty
      expect(all_for_tokens.first.available_for_tokens?).to be(true)
    end

    context 'with permission groups' do
      let(:individual_permission) { permission }
      let(:group1) do
        {
          name: 'update_wiki',
          description: 'Grants the ability to update wikis',
          permissions: %w[upload_wiki_attachment],
          available_for_tokens: true
        }
      end

      let(:group2) do
        {
          name: 'run_job',
          description: 'Grants the ability to run jobs',
          permissions: %w[play_job retry_job]
        }
      end

      let(:group1_permission) do
        {
          name: group1[:permissions].first,
          description: 'Upload wiki attachment',
          feature_category: 'wiki',
          action: nil,
          resource: nil,
          available_for_tokens: true
        }
      end

      before do
        all_groups = {
          group1[:name] => Authz::PermissionGroup.new(group1, 'group1.yml'),
          group2[:name] => Authz::PermissionGroup.new(group2, 'group2.yml')
        }
        allow(Authz::PermissionGroup).to receive(:all).and_return(all_groups)

        all_permissions = {
          group1_permission[:name] => described_class.new(group1_permission, source_file),
          permission.name => permission
        }
        allow(described_class).to receive(:all).and_return(all_permissions)
      end

      it 'includes permission groups with available_for_tokens = true' do
        expect(all_for_tokens.map(&:name)).to include(group1[:name])
      end

      it 'excludes permission groups without available_for_tokens = true' do
        expect(all_for_tokens.map(&:name)).not_to include(group2[:name])
      end

      it 'excludes permissions under a permission group' do
        expect(all_for_tokens.map(&:name)).not_to include(group1_permission[:name])
      end
    end
  end

  describe '#feature_category' do
    specify do
      expect(permission.feature_category).to eq('team_planning')
    end
  end

  describe '#source_file' do
    specify do
      expect(permission.source_file).to eq(source_file)
    end
  end

  describe '#action' do
    let(:name) { 'another_test_permission' }

    subject { permission.action }

    it { is_expected.to eq('another') }

    context 'when an action is defined' do
      let(:action) { 'another_test' }

      it 'is expected to use the defined action' do
        is_expected.to eq('another_test')
      end
    end

    context 'when a resource is defined' do
      let(:resource) { 'permission' }

      it 'is expected to infer the action based on the resource' do
        is_expected.to eq('another_test')
      end
    end

    context 'when an action and resource are defined' do
      let(:action) { 'another_test' }
      let(:resource) { 'test_permission' }

      it 'is expected use the defined action' do
        is_expected.to eq('another_test')
      end
    end
  end

  describe '#resource' do
    let(:name) { 'another_test_permission' }

    subject { permission.resource }

    it { is_expected.to eq('test_permission') }

    context 'when a resource is defined' do
      let(:resource) { 'permission' }

      it 'is expected to use the defined resource' do
        is_expected.to eq('permission')
      end
    end

    context 'when an action is defined' do
      let(:action) { 'another_test' }

      it 'is expected to infer the resource based on the action' do
        is_expected.to eq('permission')
      end
    end

    context 'when a resource and action are defined' do
      let(:action) { 'another_test' }
      let(:resource) { 'test_permission' }

      it 'is expected use the defined resource' do
        is_expected.to eq('test_permission')
      end
    end
  end

  describe '#boundaries' do
    subject { permission.boundaries }

    it { is_expected.to eq(boundaries) }

    context 'when boundaries are not defined' do
      let(:boundaries) { nil }

      it { is_expected.to eq([]) }
    end
  end
end
