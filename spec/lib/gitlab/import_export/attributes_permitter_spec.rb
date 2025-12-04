# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::AttributesPermitter, feature_category: :importers do
  let(:yml_config) do
    <<-EOF
      tree:
        project:
          - labels:
            - :priorities
          - milestones:
            - events:
              - :push_event_payload
          - ci_pipelines:
            - stages:
              - :builds

      import_only_tree:
        project:
          - ci_pipelines:
            - stages:
              - :statuses

      included_attributes:
        labels:
          - :title
          - :description

      methods:
        labels:
          - :type
    EOF
  end

  let(:file) { Tempfile.new(%w[import_export .yml]) }
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
          project: [:labels, :milestones, :ci_pipelines],
          labels: [:priorities, :title, :description, :type],
          events: [:push_event_payload],
          milestones: [:events],
          priorities: [],
          push_event_payload: [],
          ci_pipelines: [:stages],
          stages: [:builds, :statuses],
          statuses: [],
          builds: []
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
      :user                        | true
      :author                      | false
      :ci_cd_settings              | true
      :project_badges              | true
      :pipeline_schedules          | true
      :error_tracking_setting      | true
      :auto_devops                 | true
      :boards                      | true
      :custom_attributes           | true
      :label                       | true
      :labels                      | true
      :protected_branches          | true
      :protected_tags              | true
      :create_access_levels        | true
      :merge_access_levels         | true
      :push_access_levels          | true
      :releases                    | true
      :links                       | true
      :priorities                  | true
      :milestone                   | true
      :milestones                  | true
      :snippets                    | true
      :project_members             | true
      :merge_request               | true
      :merge_requests              | true
      :award_emoji                 | true
      :commit_author               | true
      :committer                   | true
      :events                      | true
      :label_links                 | true
      :merge_request_diff          | true
      :merge_request_diff_commits  | true
      :merge_request_diff_files    | true
      :metrics                     | true
      :notes                       | true
      :push_event_payload          | true
      :resource_label_events       | true
      :suggestions                 | true
      :system_note_metadata        | true
      :timelogs                    | true
      :container_expiration_policy | true
      :project_feature             | true
      :service_desk_setting        | true
      :external_pull_request       | true
      :external_pull_requests      | true
      :statuses                    | true
      :builds                      | true
      :generic_commit_statuses     | true
      :bridges                     | true
      :ci_pipelines                | true
      :stages                      | true
      :actions                     | true
      :design                      | true
      :designs                     | true
      :design_versions             | true
      :issue_assignees             | true
      :sentry_issue                | true
      :zoom_meetings               | true
      :issues                      | true
      :group_members               | true
      :project                     | true
    end

    with_them do
      it { expect(attributes_permitter.permitted_attributes_defined?(relation_name)).to eq(permitted_attributes_defined) }
    end
  end

  describe 'included_attributes for Project' do
    subject { described_class.new }

    # these are attributes for which either a special exception is made or are available only via included modules and not attribute introspection
    additional_attributes = {
      user: %w[id],
      project: %w[auto_devops_deploy_strategy auto_devops_enabled issues_enabled jobs_enabled merge_requests_enabled snippets_enabled wiki_enabled build_git_strategy build_enabled security_and_compliance_enabled requirements_enabled]
    }

    Gitlab::ImportExport::Config.new.to_h[:included_attributes].each do |relation_sym, permitted_attributes|
      context "for #{relation_sym}" do
        it_behaves_like 'a permitted attribute', relation_sym, permitted_attributes, additional_attributes[relation_sym]
      end
    end
  end
end
