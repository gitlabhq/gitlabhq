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
      :ci_cd_settings         | true
      :metrics_setting        | true
      :project_badges         | true
      :pipeline_schedules     | true
      :error_tracking_setting | true
      :auto_devops            | true
      :boards                 | true
      :custom_attributes      | true
      :labels                 | true
      :protected_branches     | true
      :protected_tags         | true
      :create_access_levels   | true
      :merge_access_levels    | true
      :push_access_levels     | true
      :releases               | true
      :links                  | true
    end

    with_them do
      it { expect(attributes_permitter.permitted_attributes_defined?(relation_name)).to eq(permitted_attributes_defined) }
    end
  end

  describe 'included_attributes for Project' do
    subject { described_class.new }

    Gitlab::ImportExport::Config.new.to_h[:included_attributes].each do |relation_sym, permitted_attributes|
      context "for #{relation_sym}" do
        it_behaves_like 'a permitted attribute', relation_sym, permitted_attributes
      end
    end
  end
end
