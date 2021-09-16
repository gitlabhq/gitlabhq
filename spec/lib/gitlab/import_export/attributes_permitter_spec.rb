# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::AttributesPermitter do
  let(:yml_config) do
    <<-EOF
      tree:
        project:
          - labels:
            - :priorities
          - milestones:
            - events:
              - :push_event_payload

      included_attributes:
        labels:
          - :title
          - :description

      methods:
        labels:
          - :type
    EOF
  end

  let(:file) { Tempfile.new(%w(import_export .yml)) }
  let(:config_hash) { Gitlab::ImportExport::Config.new(config: file.path).to_h }

  before do
    file.write(yml_config)
    file.rewind
  end

  after do
    file.close
    file.unlink
  end

  subject { described_class.new(config: config_hash) }

  describe '#permitted_attributes' do
    it 'builds permitted attributes hash' do
      expect(subject.permitted_attributes).to match(
        a_hash_including(
          project: [:labels, :milestones],
          labels: [:priorities, :title, :description, :type],
          events: [:push_event_payload],
          milestones: [:events],
          priorities: [],
          push_event_payload: []
        )
      )
    end
  end

  describe '#permit' do
    let(:unfiltered_hash) do
      {
        title: 'Title',
        description: 'Description',
        undesired_attribute: 'Undesired Attribute',
        another_attribute: 'Another Attribute'
      }
    end

    it 'only allows permitted attributes' do
      expect(subject.permit(:labels, unfiltered_hash)).to eq(title: 'Title', description: 'Description')
    end
  end

  describe '#permitted_attributes_for' do
    it 'returns an array of permitted attributes for a relation' do
      expect(subject.permitted_attributes_for(:labels)).to contain_exactly(:title, :description, :type, :priorities)
    end
  end

  describe '#permitted_attributes_defined?' do
    using RSpec::Parameterized::TableSyntax

    let(:attributes_permitter) { described_class.new }

    where(:relation_name, :permitted_attributes_defined) do
      :user                   | false
      :author                 | false
      :ci_cd_settings         | false
      :issuable_sla           | false
      :push_rule              | false
      :metrics_setting        | true
      :project_badges         | true
      :pipeline_schedules     | true
      :error_tracking_setting | true
      :auto_devops            | true
    end

    with_them do
      it { expect(attributes_permitter.permitted_attributes_defined?(relation_name)).to eq(permitted_attributes_defined) }
    end
  end

  describe 'included_attributes for Project' do
    let(:prohibited_attributes) { %i[remote_url my_attributes my_ids token my_id test] }

    subject { described_class.new }

    Gitlab::ImportExport::Config.new.to_h[:included_attributes].each do |relation_sym, permitted_attributes|
      context "for #{relation_sym}" do
        let(:import_export_config) { Gitlab::ImportExport::Config.new.to_h }
        let(:project_relation_factory) { Gitlab::ImportExport::Project::RelationFactory }

        let(:relation_hash) { (permitted_attributes + prohibited_attributes).map(&:to_s).zip([]).to_h }
        let(:relation_name) { project_relation_factory.overrides[relation_sym]&.to_sym || relation_sym }
        let(:relation_class) { project_relation_factory.relation_class(relation_name) }
        let(:excluded_keys) { import_export_config.dig(:excluded_keys, relation_sym) || [] }

        let(:cleaned_hash) do
          Gitlab::ImportExport::AttributeCleaner.new(
            relation_hash: relation_hash,
            relation_class: relation_class,
            excluded_keys: excluded_keys
          ).clean
        end

        let(:permitted_hash) { subject.permit(relation_sym, relation_hash) }

        if described_class.new.permitted_attributes_defined?(relation_sym)
          it 'contains only attributes that are defined as permitted in the import/export config' do
            expect(permitted_hash.keys).to contain_exactly(*permitted_attributes.map(&:to_s))
          end

          it 'does not contain attributes that would be cleaned with AttributeCleaner' do
            expect(cleaned_hash.keys).to include(*permitted_hash.keys)
          end

          it 'does not contain prohibited attributes that are not related to given relation' do
            expect(permitted_hash.keys).not_to include(*prohibited_attributes.map(&:to_s))
          end
        else
          it 'is disabled' do
            expect(subject).not_to be_permitted_attributes_defined(relation_sym)
          end
        end
      end
    end
  end
end
