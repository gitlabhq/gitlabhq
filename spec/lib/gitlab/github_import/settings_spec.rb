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
      [
        {
          name: 'single_endpoint_notes_import',
          label: s_('GitHubImporter|Use alternative comments import method'),
          selected: false,
          details: s_('GitHubImporter|The default method can skip some comments in large ' \
            'projects because of limitations of the GitHub API.')
        },
        {
          name: 'attachments_import',
          label: s_('GitHubImporter|Import Markdown attachments (links)'),
          selected: false,
          details: s_('GitHubImporter|Import Markdown attachments (links) from repository ' \
            'comments, release posts, issue descriptions, and pull request ' \
            'descriptions. These can include images, text, or binary attachments. ' \
            'If not imported, links in Markdown to attachments break after you ' \
            'remove the attachments from GitHub.')
        },
        {
          name: 'collaborators_import',
          label: s_('GitHubImporter|Import collaborators'),
          selected: true,
          details: s_('GitHubImporter|Import direct repository collaborators who are not ' \
            'outside collaborators. Imported collaborators who aren\'t members ' \
            'of the group you imported the project into consume seats on your ' \
            'GitLab instance.')
        }
      ]
    end

    it 'returns stages list as array' do
      expect(described_class.stages_array(project.owner)).to match_array(expected_list)
    end

    it 'returns non-nil label and details for every stage' do
      described_class.stages_array(project.owner).each do |stage|
        expect(stage[:label]).not_to be_nil, "expected label for #{stage[:name]}"
        expect(stage[:details]).not_to be_nil, "expected details for #{stage[:name]}"
      end
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
    it 'returns true after writing settings' do
      project.build_or_assign_import_data(credentials: { user: 'token' })
      settings.write(data_input)

      expect(settings.user_mapping_enabled?).to be(true)
    end
  end

  describe '#map_to_personal_namespace_owner?' do
    let_it_be(:group) { create(:group) }
    let_it_be(:user) { create(:user, :with_namespace) }

    subject do
      settings.write(data_input)
      settings.map_to_personal_namespace_owner?
    end

    context 'when project is imported into a personal namespace' do
      before do
        project.update!(namespace: user.namespace)
      end

      it { is_expected.to be(true) }
    end

    context 'when project is imported into a group' do
      before_all do
        project.update!(namespace: group)
      end

      it { is_expected.to be(false) }
    end
  end
end
