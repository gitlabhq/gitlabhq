# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Audit::Type::Definition do
  let(:attributes) do
    { name: 'group_deploy_token_destroyed',
      description: 'Group deploy token is deleted',
      introduced_by_issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/1',
      introduced_by_mr: 'https://gitlab.com/gitlab-org/gitlab/-/merge_requests/1',
      feature_category: 'continuous_delivery',
      milestone: '15.4',
      saved_to_database: true,
      streamed: true,
      scope: ["Group"] }
  end

  let(:path) { File.join('types', 'group_deploy_token_destroyed.yml') }
  let(:definition) { described_class.new(path, attributes) }
  let(:yaml_content) { attributes.deep_stringify_keys.to_yaml }

  around do |example|
    described_class.clear_memoization(:definitions)
    example.run
    described_class.clear_memoization(:definitions)
  end

  describe '#key' do
    subject { definition.key }

    it 'returns a symbol from name' do
      is_expected.to eq(:group_deploy_token_destroyed)
    end
  end

  describe '#validate!', :aggregate_failures do
    using RSpec::Parameterized::TableSyntax

    # rubocop:disable Layout/LineLength
    where(:param, :value, :result) do
      :path                | 'audit_event/types/invalid.yml' | /Audit event type 'group_deploy_token_destroyed' has an invalid path/
      :name                | nil                             | %r{property '/name' is not of type: string}
      :description         | nil                             | %r{property '/description' is not of type: string}
      :introduced_by_issue | nil                             | %r{property '/introduced_by_issue' is not of type: string}
      :introduced_by_mr    | nil                             | %r{property '/introduced_by_mr' is not of type: string}
      :feature_category    | nil                             | %r{property '/feature_category' is not of type: string}
      :milestone           | nil                             | %r{property '/milestone' is not of type: string}
      :scope               | nil                             | %r{property '/scope' is not of type: array}
    end
    # rubocop:enable Layout/LineLength

    with_them do
      let(:params) { attributes.merge(path: path) }

      before do
        params[param] = value
      end

      it do
        expect do
          described_class.new(
            params[:path], params.except(:path)
          ).validate!
        end.to raise_error(result)
      end
    end

    context 'when both saved_to_database and streamed are false' do
      let(:params) { attributes.merge({ path: path, saved_to_database: false, streamed: false }) }

      it 'raises an exception' do
        expect do
          described_class.new(
            params[:path], params.except(:path)
          ).validate!
        end.to raise_error(/root is invalid: error_type=not/)
      end
    end
  end

  describe '.paths' do
    it 'returns at least one path' do
      expect(described_class.paths).not_to be_empty
    end
  end

  describe '.get' do
    before do
      allow(described_class).to receive(:definitions) do
        { definition.key => definition }
      end
    end

    context 'when audit event type is not defined' do
      let(:undefined_audit_event_type) { 'undefined_audit_event_type' }

      it 'returns nil' do
        expect(described_class.get(undefined_audit_event_type)).to be nil
      end
    end

    context 'when audit event type is defined' do
      let(:audit_event_type) { 'group_deploy_token_destroyed' }

      it 'returns an instance of Gitlab::Audit::Type::Definition' do
        expect(described_class.get(audit_event_type)).to be_an_instance_of(described_class)
      end

      it 'returns the properties as defined for that audit event type', :aggregate_failures do
        audit_event_type_definition = described_class.get(audit_event_type)

        expect(audit_event_type_definition.name).to eq "group_deploy_token_destroyed"
        expect(audit_event_type_definition.description).to eq "Group deploy token is deleted"
        expect(audit_event_type_definition.feature_category).to eq "continuous_delivery"
        expect(audit_event_type_definition.milestone).to eq "15.4"
        expect(audit_event_type_definition.saved_to_database).to be true
        expect(audit_event_type_definition.streamed).to be true
        expect(audit_event_type_definition.scope).to eq ["Group"]
      end
    end
  end

  describe '.event_names' do
    before do
      allow(described_class).to receive(:definitions) do
        { definition.key => definition }
      end
    end

    it 'returns names of event types as string array' do
      expect(described_class.event_names).to match_array([definition.attributes[:name]])
    end
  end

  describe '.defined?' do
    before do
      allow(described_class).to receive(:definitions) do
        { definition.key => definition }
      end
    end

    it 'returns true if definition for the event name exists' do
      expect(described_class.defined?('group_deploy_token_destroyed')).to be_truthy
    end

    it 'returns false if definition for the event name exists' do
      expect(described_class.defined?('random_event_name')).to be_falsey
    end
  end

  describe '.stream_only?' do
    let(:stream_only_event_attributes) do
      { name: 'policy_project_updated',
        description: 'This event is triggered whenever the security policy project is updated for a project',
        introduced_by_issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/2',
        introduced_by_mr: 'https://gitlab.com/gitlab-org/gitlab/-/merge_requests/2',
        feature_category: 'security_policy_management',
        milestone: '15.6',
        saved_to_database: false,
        streamed: true }
    end

    let(:stream_only_event_path) { File.join('types', 'policy_project_updated.yml') }
    let(:stream_only_event_definition) { described_class.new(stream_only_event_path, stream_only_event_attributes) }

    before do
      allow(described_class).to receive(:definitions) do
        { definition.key => definition,
          stream_only_event_definition.key => stream_only_event_definition }
      end
    end

    it 'returns true for a stream only event' do
      expect(described_class.stream_only?('group_deploy_token_destroyed')).to be_falsey
    end

    it 'returns false for an event that is saved to database' do
      expect(described_class.stream_only?('policy_project_updated')).to be_truthy
    end
  end

  describe '.load_from_file' do
    it 'properly loads a definition from file' do
      expect_file_read(path, content: yaml_content)

      expect(described_class.send(:load_from_file, path).attributes)
        .to eq(definition.attributes)
    end

    context 'for missing file' do
      let(:path) { 'missing/audit_events/type/file.yml' }

      it 'raises exception' do
        expect do
          described_class.send(:load_from_file, path)
        end.to raise_error(/Invalid definition for/)
      end
    end

    context 'for invalid definition' do
      it 'raises exception' do
        expect_file_read(path, content: '{}')

        expect do
          described_class.send(:load_from_file, path)
        end.to raise_error(%r{property '/name' is not of type: string})
      end
    end
  end

  describe '.load_all!' do
    let(:store1) { Dir.mktmpdir('path1') }
    let(:store2) { Dir.mktmpdir('path2') }
    let(:definitions) { {} }

    before do
      allow(described_class).to receive(:paths).and_return(
        [
          File.join(store1, '**', '*.yml'),
          File.join(store2, '**', '*.yml')
        ]
      )
    end

    subject { described_class.send(:load_all!) }

    after do
      FileUtils.rm_rf(store1)
      FileUtils.rm_rf(store2)
    end

    it "when there are no audit event types a list of definitions is empty" do
      is_expected.to be_empty
    end

    it "when there's a single audit event type it properly loads them" do
      write_audit_event_type(store1, path, yaml_content)

      is_expected.to be_one
    end

    it "when the same audit event type is stored multiple times raises exception" do
      write_audit_event_type(store1, path, yaml_content)
      write_audit_event_type(store2, path, yaml_content)

      expect { subject }
        .to raise_error(/Audit event type 'group_deploy_token_destroyed' is already defined/)
    end

    it "when one of the YAMLs is invalid it does raise exception" do
      write_audit_event_type(store1, path, '{}')

      expect { subject }.to raise_error(/Invalid definition for .* '' must match the filename/)
    end
  end

  describe 'validate that all the YAML definitions matches the audit event type schema' do
    it 'successfully loads all the YAML definitions' do
      expect { described_class.definitions }.not_to raise_error
    end
  end

  describe '.definitions' do
    let(:store1) { Dir.mktmpdir('path1') }

    before do
      allow(described_class).to receive(:paths).and_return(
        [
          File.join(store1, '**', '*.yml')
        ]
      )
    end

    subject { described_class.definitions }

    after do
      FileUtils.rm_rf(store1)
    end

    it "loads the definitions for all the audit event types" do
      write_audit_event_type(store1, path, yaml_content)

      is_expected.to be_one
    end
  end

  describe '.names_with_category' do
    let(:store1) { Dir.mktmpdir('path1') }

    before do
      allow(described_class).to receive(:paths).and_return(
        [
          File.join(store1, '**', '*.yml')
        ]
      )
    end

    subject { described_class.names_with_category }

    after do
      FileUtils.rm_rf(store1)
    end

    it "returns an array with just the event name and feature category" do
      write_audit_event_type(store1, path, yaml_content)

      expect(subject).to eq([{ event_name: :group_deploy_token_destroyed, feature_category: 'continuous_delivery' }])
    end
  end

  def write_audit_event_type(store, path, content)
    path = File.join(store, path)
    dir = File.dirname(path)
    FileUtils.mkdir_p(dir)
    File.write(path, content)
  end
end
