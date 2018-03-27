require 'spec_helper'

describe Gitlab::ImportExport::Reader  do
  let(:shared) { Gitlab::ImportExport::Shared.new(nil) }
  let(:test_config) { 'spec/support/import_export/import_export.yml' }
  let(:project_tree_hash) do
    {
      except: [:id, :created_at],
      include: [:issues, :labels,
                { merge_requests: {
                  only: [:id],
                  except: [:iid],
                  include: [:merge_request_diff, :merge_request_test]
                } },
                { commit_statuses: { include: :commit } },
                { project_members: { include: { user: { only: [:email] } } } }]
    }
  end

  before do
    allow_any_instance_of(Gitlab::ImportExport).to receive(:config_file).and_return(test_config)
  end

  it 'generates hash from project tree config' do
    expect(described_class.new(shared: shared).project_tree).to match(project_tree_hash)
  end

  context 'individual scenarios' do
    it 'generates the correct hash for a single project relation' do
      setup_yaml(project_tree: [:issues])

      expect(described_class.new(shared: shared).project_tree).to match(include: [:issues])
    end

    it 'generates the correct hash for a single project feature relation' do
      setup_yaml(project_tree: [:project_feature])

      expect(described_class.new(shared: shared).project_tree).to match(include: [:project_feature])
    end

    it 'generates the correct hash for a multiple project relation' do
      setup_yaml(project_tree: [:issues, :snippets])

      expect(described_class.new(shared: shared).project_tree).to match(include: [:issues, :snippets])
    end

    it 'generates the correct hash for a single sub-relation' do
      setup_yaml(project_tree: [issues: [:notes]])

      expect(described_class.new(shared: shared).project_tree).to match(include: [{ issues: { include: :notes } }])
    end

    it 'generates the correct hash for a multiple sub-relation' do
      setup_yaml(project_tree: [merge_requests: [:notes, :merge_request_diff]])

      expect(described_class.new(shared: shared).project_tree).to match(include: [{ merge_requests: { include: [:notes, :merge_request_diff] } }])
    end

    it 'generates the correct hash for a sub-relation with another sub-relation' do
      setup_yaml(project_tree: [merge_requests: [notes: :author]])

      expect(described_class.new(shared: shared).project_tree).to match(include: [{ merge_requests: { include: { notes: { include: :author } } } }])
    end

    it 'generates the correct hash for a relation with included attributes' do
      setup_yaml(project_tree: [:issues], included_attributes: { issues: [:name, :description] })

      expect(described_class.new(shared: shared).project_tree).to match(include: [{ issues: { only: [:name, :description] } }])
    end

    it 'generates the correct hash for a relation with excluded attributes' do
      setup_yaml(project_tree: [:issues], excluded_attributes: { issues: [:name] })

      expect(described_class.new(shared: shared).project_tree).to match(include: [{ issues: { except: [:name] } }])
    end

    it 'generates the correct hash for a relation with both excluded and included attributes' do
      setup_yaml(project_tree: [:issues], excluded_attributes: { issues: [:name] }, included_attributes: { issues: [:description] })

      expect(described_class.new(shared: shared).project_tree).to match(include: [{ issues: { except: [:name], only: [:description] } }])
    end

    it 'generates the correct hash for a relation with custom methods' do
      setup_yaml(project_tree: [:issues], methods: { issues: [:name] })

      expect(described_class.new(shared: shared).project_tree).to match(include: [{ issues: { methods: [:name] } }])
    end

    it 'generates the correct hash for group members' do
      expect(described_class.new(shared: shared).group_members_tree).to match({ include: { user: { only: [:email] } } })
    end

    def setup_yaml(hash)
      allow(YAML).to receive(:load_file).with(test_config).and_return(hash)
    end
  end
end
