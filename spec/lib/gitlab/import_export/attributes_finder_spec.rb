# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::ImportExport::AttributesFinder do
  describe '#find_root' do
    subject { described_class.new(config: config).find_root(model_key) }

    let(:test_config) { 'spec/support/import_export/import_export.yml' }
    let(:config) { Gitlab::ImportExport::Config.new.to_h }
    let(:model_key) { :project }

    let(:project_tree_hash) do
      {
        except: [:id, :created_at],
        include: [
          { issues: { include: [] } },
          { labels: { include: [] } },
          { merge_requests: {
            except: [:iid],
            include: [
              { merge_request_diff: {
                include: []
              } },
              { merge_request_test: { include: [] } }
            ],
            only: [:id]
            } },
          { commit_statuses: {
              include: [{ commit: { include: [] } }]
            } },
          { project_members: {
              include: [{ user: { include: [],
                                  only: [:email] } }]
          } }
        ]
      }
    end

    before do
      allow_any_instance_of(Gitlab::ImportExport).to receive(:config_file).and_return(test_config)
    end

    it 'generates hash from project tree config' do
      is_expected.to match(project_tree_hash)
    end

    context 'individual scenarios' do
      it 'generates the correct hash for a single project relation' do
        setup_yaml(tree: { project: [:issues] })

        is_expected.to match(
          include: [{ issues: { include: [] } }]
        )
      end

      it 'generates the correct hash for a single project feature relation' do
        setup_yaml(tree: { project: [:project_feature] })

        is_expected.to match(
          include: [{ project_feature: { include: [] } }]
        )
      end

      it 'generates the correct hash for a multiple project relation' do
        setup_yaml(tree: { project: [:issues, :snippets] })

        is_expected.to match(
          include: [{ issues: { include: [] } },
                    { snippets: { include: [] } }]
        )
      end

      it 'generates the correct hash for a single sub-relation' do
        setup_yaml(tree: { project: [issues: [:notes]] })

        is_expected.to match(
          include: [{ issues: { include: [{ notes: { include: [] } }] } }]
        )
      end

      it 'generates the correct hash for a multiple sub-relation' do
        setup_yaml(tree: { project: [merge_requests: [:notes, :merge_request_diff]] })

        is_expected.to match(
          include: [{ merge_requests:
                      { include: [{ notes: { include: [] } },
                                  { merge_request_diff: { include: [] } }] } }]
        )
      end

      it 'generates the correct hash for a sub-relation with another sub-relation' do
        setup_yaml(tree: { project: [merge_requests: [notes: [:author]]] })

        is_expected.to match(
          include: [{ merge_requests: {
                      include: [{ notes: { include: [{ author: { include: [] } }] } }]
                    } }]
        )
      end

      it 'generates the correct hash for a relation with included attributes' do
        setup_yaml(tree: { project: [:issues] },
                  included_attributes: { issues: [:name, :description] })

        is_expected.to match(
          include: [{ issues: { include: [],
                                only: [:name, :description] } }]
        )
      end

      it 'generates the correct hash for a relation with excluded attributes' do
        setup_yaml(tree: { project: [:issues] },
                  excluded_attributes: { issues: [:name] })

        is_expected.to match(
          include: [{ issues: { except: [:name],
                                include: [] } }]
        )
      end

      it 'generates the correct hash for a relation with both excluded and included attributes' do
        setup_yaml(tree: { project: [:issues] },
                  excluded_attributes: { issues: [:name] },
                  included_attributes: { issues: [:description] })

        is_expected.to match(
          include: [{ issues: { except: [:name],
                                include: [],
                                only: [:description] } }]
        )
      end

      it 'generates the correct hash for a relation with custom methods' do
        setup_yaml(tree: { project: [:issues] },
                  methods: { issues: [:name] })

        is_expected.to match(
          include: [{ issues: { include: [],
                                methods: [:name] } }]
        )
      end

      def setup_yaml(hash)
        allow(YAML).to receive(:load_file).with(test_config).and_return(hash)
      end
    end
  end

  describe '#find_relations_tree' do
    subject { described_class.new(config: config).find_relations_tree(model_key) }

    let(:tree) { { project: { issues: {} } } }
    let(:model_key) { :project }

    context 'when initialized with config including tree' do
      let(:config) { { tree: tree } }

      context 'when relation is in top-level keys of the tree' do
        it { is_expected.to eq({ issues: {} }) }
      end

      context 'when the relation is not in top-level keys' do
        let(:model_key) { :issues }

        it { is_expected.to be_nil }
      end
    end

    context 'when tree is not present in config' do
      let(:config) { {} }

      it { is_expected.to be_nil }
    end
  end

  describe '#find_excluded_keys' do
    subject { described_class.new(config: config).find_excluded_keys(klass_name) }

    let(:klass_name) { 'project' }

    context 'when initialized with excluded_attributes' do
      let(:config) { { excluded_attributes: excluded_attributes } }
      let(:excluded_attributes) { { project: [:name, :path], issues: [:milestone_id] } }

      it { is_expected.to eq(%w[name path]) }
    end

    context 'when excluded_attributes are not present in config' do
      let(:config) { {} }

      it { is_expected.to eq([]) }
    end
  end
end
