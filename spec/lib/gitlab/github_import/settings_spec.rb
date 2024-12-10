# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Settings, feature_category: :importers do
  subject(:settings) { described_class.new(project) }

  let_it_be_with_reload(:project) { create(:project, import_type: ::Import::SOURCE_GITHUB.to_s) }

  let(:optional_stages) do
    {
      single_endpoint_notes_import: false,
      attachments_import: false,
      collaborators_import: false
    }
  end

  let(:data_input) do
    {
      optional_stages: {
        single_endpoint_notes_import: 'false',
        attachments_import: nil,
        collaborators_import: false,
        foo: :bar
      },
      pagination_limit: 50,
      timeout_strategy: "optimistic"
    }.stringify_keys
  end

  describe '.stages_array' do
    let(:expected_list) do
      stages = described_class::OPTIONAL_STAGES
      [
        {
          name: 'single_endpoint_notes_import',
          label: stages[:single_endpoint_notes_import][:label],
          selected: false,
          details: stages[:single_endpoint_notes_import][:details]
        },
        {
          name: 'attachments_import',
          label: stages[:attachments_import][:label].strip,
          selected: false,
          details: stages[:attachments_import][:details]
        },
        {
          name: 'collaborators_import',
          label: stages[:collaborators_import][:label].strip,
          selected: true,
          details: stages[:collaborators_import][:details]
        }
      ]
    end

    it 'returns stages list as array' do
      expect(described_class.stages_array(project.owner)).to match_array(expected_list)
    end
  end

  describe '#write' do
    it 'puts optional steps, timeout strategy, user mapping setting and pagination_limit into projects import_data' do
      project.build_or_assign_import_data(credentials: { user: 'token' })

      settings.write(data_input)

      expect(project.import_data.data['optional_stages'])
        .to eq optional_stages.stringify_keys
      expect(project.import_data.data['timeout_strategy'])
        .to eq("optimistic")
      expect(project.import_data.data['user_contribution_mapping_enabled'])
        .to be true
      expect(project.import_data.data['pagination_limit'])
        .to eq(50)
    end
  end

  describe '#enabled?' do
    it 'returns is enabled or not specific optional stage' do
      project.build_or_assign_import_data(data: { optional_stages: optional_stages })

      expect(settings.enabled?(:single_endpoint_notes_import)).to eq false
      expect(settings.enabled?(:attachments_import)).to eq false
      expect(settings.enabled?(:collaborators_import)).to eq false
    end
  end

  describe '#disabled?' do
    it 'returns is disabled or not specific optional stage' do
      project.build_or_assign_import_data(data: { optional_stages: optional_stages })

      expect(settings.disabled?(:single_endpoint_notes_import)).to eq true
      expect(settings.disabled?(:attachments_import)).to eq true
      expect(settings.disabled?(:collaborators_import)).to eq true
    end
  end

  describe '#user_mapping_enabled?' do
    subject do
      settings.write(data_input)
      settings.user_mapping_enabled?
    end

    before do
      project.build_or_assign_import_data(credentials: { user: 'token' })
    end

    shared_examples 'when :importer_user_mapping is disabled' do
      before do
        Feature.disable(:importer_user_mapping)
      end

      it { is_expected.to be(false) }
    end

    shared_examples 'when :github_user_mapping is disabled' do |expected_enabled:|
      before do
        Feature.disable(:github_user_mapping)
      end

      it { is_expected.to be(expected_enabled) }
    end

    shared_examples 'when :gitea_user_mapping is disabled' do |expected_enabled:|
      before do
        Feature.disable(:gitea_user_mapping)
      end

      it { is_expected.to be(expected_enabled) }
    end

    context 'when the project is a GitHub import' do
      it { is_expected.to be(true) }

      it_behaves_like 'when :importer_user_mapping is disabled'
      it_behaves_like 'when :github_user_mapping is disabled', expected_enabled: false
      it_behaves_like 'when :gitea_user_mapping is disabled', expected_enabled: true
    end

    context 'when the project is a Gitea import' do
      before do
        project.update!(import_type: ::Import::SOURCE_GITEA.to_s)
      end

      it { is_expected.to be(true) }

      it_behaves_like 'when :importer_user_mapping is disabled'
      it_behaves_like 'when :gitea_user_mapping is disabled', expected_enabled: false
      it_behaves_like 'when :github_user_mapping is disabled', expected_enabled: true
    end

    context 'when the project does not have an import_type' do
      before do
        project.update!(import_type: nil)
      end

      it { is_expected.to be(false) }

      it_behaves_like 'when :importer_user_mapping is disabled'
      it_behaves_like 'when :gitea_user_mapping is disabled', expected_enabled: false
      it_behaves_like 'when :github_user_mapping is disabled', expected_enabled: false
    end

    context 'when the project has an import_type without a user mapping flag' do
      before do
        project.update!(import_type: ::Import::SOURCE_BITBUCKET.to_s)
      end

      it { is_expected.to be(false) }

      it_behaves_like 'when :importer_user_mapping is disabled'
      it_behaves_like 'when :gitea_user_mapping is disabled', expected_enabled: false
      it_behaves_like 'when :github_user_mapping is disabled', expected_enabled: false
    end
  end
end
