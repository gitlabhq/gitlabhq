# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::RelationFactory do
  let(:group)   { create(:group) }
  let(:project) { create(:project, :repository, group: group) }
  let(:members_mapper) { double('members_mapper').as_null_object }
  let(:merge_requests_mapping) { {} }
  let(:user) { create(:admin) }
  let(:excluded_keys) { [] }
  let(:created_object) do
    described_class.create(relation_sym: relation_sym,
                           relation_hash: relation_hash,
                           members_mapper: members_mapper,
                           merge_requests_mapping: merge_requests_mapping,
                           user: user,
                           project: project,
                           excluded_keys: excluded_keys)
  end

  context 'hook object' do
    let(:relation_sym) { :hooks }
    let(:id) { 999 }
    let(:service_id) { 99 }
    let(:original_project_id) { 8 }
    let(:token) { 'secret' }

    let(:relation_hash) do
      {
        'id' => id,
        'url' => 'https://example.json',
        'project_id' => original_project_id,
        'created_at' => '2016-08-12T09:41:03.462Z',
        'updated_at' => '2016-08-12T09:41:03.462Z',
        'service_id' => service_id,
        'push_events' => true,
        'issues_events' => false,
        'confidential_issues_events' => false,
        'merge_requests_events' => true,
        'tag_push_events' => false,
        'note_events' => true,
        'enable_ssl_verification' => true,
        'job_events' => false,
        'wiki_page_events' => true,
        'token' => token
      }
    end

    it 'does not have the original ID' do
      expect(created_object.id).not_to eq(id)
    end

    it 'does not have the original service_id' do
      expect(created_object.service_id).not_to eq(service_id)
    end

    it 'does not have the original project_id' do
      expect(created_object.project_id).not_to eq(original_project_id)
    end

    it 'has the new project_id' do
      expect(created_object.project_id).to eql(project.id)
    end

    it 'has a nil token' do
      expect(created_object.token).to eq(nil)
    end

    context 'original service exists' do
      let(:service_id) { create(:service, project: project).id }

      it 'does not have the original service_id' do
        expect(created_object.service_id).not_to eq(service_id)
      end
    end

    context 'excluded attributes' do
      let(:excluded_keys) { %w[url] }

      it 'are removed from the imported object' do
        expect(created_object.url).to be_nil
      end
    end
  end

  # Mocks an ActiveRecordish object with the dodgy columns
  class FooModel
    include ActiveModel::Model

    def initialize(params = {})
      params.each { |key, value| send("#{key}=", value) }
    end

    def values
      instance_variables.map { |ivar| instance_variable_get(ivar) }
    end
  end

  context 'merge_requset object' do
    let(:relation_sym) { :merge_requests }

    let(:exported_member) do
      {
        "id" => 111,
        "access_level" => 30,
        "source_id" => 1,
        "source_type" => "Project",
        "user_id" => 3,
        "notification_level" => 3,
        "created_at" => "2016-11-18T09:29:42.634Z",
        "updated_at" => "2016-11-18T09:29:42.634Z",
        "user" => {
          "id" => user.id,
          "email" => user.email,
          "username" => user.username
        }
      }
    end

    let(:members_mapper) do
      Gitlab::ImportExport::MembersMapper.new(
        exported_members: [exported_member],
        user: user,
        importable: project)
    end

    let(:relation_hash) do
      {
        'id' => 27,
        'target_branch' => "feature",
        'source_branch' => "feature_conflict",
        'source_project_id' => project.id,
        'target_project_id' => project.id,
        'author_id' => user.id,
        'assignee_id' => user.id,
        'updated_by_id' => user.id,
        'title' => "MR1",
        'created_at' => "2016-06-14T15:02:36.568Z",
        'updated_at' => "2016-06-14T15:02:56.815Z",
        'state' => "opened",
        'merge_status' => "unchecked",
        'description' => "Description",
        'position' => 0,
        'source_branch_sha' => "ABCD",
        'target_branch_sha' => "DCBA",
        'merge_when_pipeline_succeeds' => true
      }
    end

    it 'has preloaded author' do
      expect(created_object.author).to equal(user)
    end

    it 'has preloaded updated_by' do
      expect(created_object.updated_by).to equal(user)
    end

    it 'has preloaded source project' do
      expect(created_object.source_project).to equal(project)
    end

    it 'has preloaded target project' do
      expect(created_object.source_project).to equal(project)
    end
  end

  context 'label object' do
    let(:relation_sym) { :labels }
    let(:relation_hash) do
      {
        "id": 3,
        "title": "test3",
        "color": "#428bca",
        "group_id": project.group.id,
        "created_at": "2016-07-22T08:55:44.161Z",
        "updated_at": "2016-07-22T08:55:44.161Z",
        "template": false,
        "description": "",
        "project_id": project.id,
        "type": "GroupLabel"
      }
    end

    it 'has preloaded project' do
      expect(created_object.project).to equal(project)
    end

    it 'has preloaded group' do
      expect(created_object.group).to equal(project.group)
    end
  end

  # `project_id`, `described_class.USER_REFERENCES`, noteable_id, target_id, and some project IDs are already
  # re-assigned by described_class.
  context 'Potentially hazardous foreign keys' do
    let(:relation_sym) { :hazardous_foo_model }
    let(:relation_hash) do
      {
        'service_id' => 99,
        'moved_to_id' => 99,
        'namespace_id' => 99,
        'ci_id' => 99,
        'random_project_id' => 99,
        'random_id' => 99,
        'milestone_id' => 99,
        'project_id' => 99,
        'user_id' => 99
      }
    end

    class HazardousFooModel < FooModel
      attr_accessor :service_id, :moved_to_id, :namespace_id, :ci_id, :random_project_id, :random_id, :milestone_id, :project_id
    end

    it 'does not preserve any foreign key IDs' do
      expect(created_object.values).not_to include(99)
    end
  end

  context 'overrided model with pluralized name' do
    let(:relation_sym) { :metrics }

    let(:relation_hash) do
      {
        'id' => 99,
        'merge_request_id' => 99,
        'merged_at' => Time.now,
        'merged_by_id' => 99,
        'latest_closed_at' => nil,
        'latest_closed_by_id' => nil
      }
    end

    it 'does not raise errors' do
      expect { created_object }.not_to raise_error
    end
  end

  context 'Project references' do
    let(:relation_sym) { :project_foo_model }
    let(:relation_hash) do
      Gitlab::ImportExport::RelationFactory::PROJECT_REFERENCES.map { |ref| { ref => 99 } }.inject(:merge)
    end

    class ProjectFooModel < FooModel
      attr_accessor(*Gitlab::ImportExport::RelationFactory::PROJECT_REFERENCES)
    end

    it 'does not preserve any project foreign key IDs' do
      expect(created_object.values).not_to include(99)
    end
  end

  context 'Notes user references' do
    let(:relation_sym) { :notes }
    let(:new_user) { create(:user) }
    let(:exported_member) do
      {
        "id" => 111,
        "access_level" => 30,
        "source_id" => 1,
        "source_type" => "Project",
        "user_id" => 3,
        "notification_level" => 3,
        "created_at" => "2016-11-18T09:29:42.634Z",
        "updated_at" => "2016-11-18T09:29:42.634Z",
        "user" => {
          "id" => 999,
          "email" => new_user.email,
          "username" => new_user.username
        }
      }
    end

    let(:relation_hash) do
      {
        "id" => 4947,
        "note" => "merged",
        "noteable_type" => "MergeRequest",
        "author_id" => 999,
        "created_at" => "2016-11-18T09:29:42.634Z",
        "updated_at" => "2016-11-18T09:29:42.634Z",
        "project_id" => 1,
        "attachment" => {
          "url" => nil
        },
        "noteable_id" => 377,
        "system" => true,
        "author" => {
          "name" => "Administrator"
        },
        "events" => []
      }
    end

    let(:members_mapper) do
      Gitlab::ImportExport::MembersMapper.new(
        exported_members: [exported_member],
        user: user,
        importable: project)
    end

    it 'maps the right author to the imported note' do
      expect(created_object.author).to eq(new_user)
    end
  end

  context 'encrypted attributes' do
    let(:relation_sym) { 'Ci::Variable' }
    let(:relation_hash) do
      create(:ci_variable).as_json
    end

    it 'has no value for the encrypted attribute' do
      expect(created_object.value).to be_nil
    end
  end
end
