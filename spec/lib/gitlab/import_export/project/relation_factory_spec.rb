# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Project::RelationFactory, :use_clean_rails_memory_store_caching, feature_category: :importers do
  let(:group) { create(:group, maintainers: importer_user) }
  let(:members_mapper) { double('members_mapper').as_null_object }
  let(:project) { create(:project, :repository, group: group) }
  let(:admin) { create(:admin) }
  let(:importer_user) { admin }
  let(:excluded_keys) { [] }
  let(:additional_relation_attributes) { {} }
  let(:created_object) do
    described_class.create( # rubocop:disable Rails/SaveBang
      relation_sym: relation_sym,
      relation_hash: relation_hash.merge(additional_relation_attributes),
      relation_index: 1,
      object_builder: Gitlab::ImportExport::Project::ObjectBuilder,
      members_mapper: members_mapper,
      user: importer_user,
      importable: project,
      import_source: ::Import::SOURCE_PROJECT_EXPORT_IMPORT,
      excluded_keys: excluded_keys,
      rewrite_mentions: true
    )
  end

  before do
    # Mocks an ActiveRecordish object with the dodgy columns
    stub_const('FooModel', Class.new)
    FooModel.class_eval do
      include ActiveModel::Model
      include ActiveModel::AttributeMethods

      def initialize(params = {})
        params.each { |key, value| send("#{key}=", value) }
      end

      def values
        instance_variables.map { |ivar| instance_variable_get(ivar) }
      end
    end
  end

  context 'hook object' do
    let(:relation_sym) { :hooks }
    let(:id) { 999 }
    let(:integration_id) { 99 }
    let(:original_project_id) { 8 }
    let(:token) { 'secret' }

    let(:relation_hash) do
      {
        'id' => id,
        'url' => 'https://example.json',
        'project_id' => original_project_id,
        'created_at' => '2016-08-12T09:41:03.462Z',
        'updated_at' => '2016-08-12T09:41:03.462Z',
        'integration_id' => integration_id,
        'push_events' => true,
        'issues_events' => false,
        'confidential_issues_events' => false,
        'merge_requests_events' => true,
        'tag_push_events' => false,
        'note_events' => true,
        'enable_ssl_verification' => true,
        'job_events' => false,
        'wiki_page_events' => true,
        'releases_events' => false,
        'emoji_events' => false,
        'resource_access_token_events' => false,
        'token' => token
      }
    end

    it 'does not have the original ID' do
      expect(created_object.id).not_to eq(id)
    end

    it 'does not have the original integration_id' do
      expect(created_object.integration_id).not_to eq(integration_id)
    end

    it 'has the new project_id' do
      expect(created_object.project_id).to eql(project.id)
    end

    it 'has a nil token' do
      expect(created_object.token).to eq(nil)
    end

    context 'original service exists' do
      let(:integration_id) { create(:integration, project: project).id }

      it 'does not have the original integration_id' do
        expect(created_object.integration_id).not_to eq(integration_id)
      end
    end

    context 'excluded attributes' do
      let(:excluded_keys) { %w[url] }

      it 'are removed from the imported object' do
        expect(created_object.url).to be_nil
      end
    end
  end

  context 'merge_request object' do
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
          "id" => admin.id,
          "public_email" => admin.email,
          "username" => admin.username
        }
      }
    end

    let(:members_mapper) do
      Gitlab::ImportExport::MembersMapper.new(
        exported_members: [exported_member],
        user: importer_user,
        importable: project)
    end

    let(:relation_hash) do
      {
        'id' => 27,
        'target_branch' => "feature",
        'source_branch' => "feature_conflict",
        'source_project_id' => project.id,
        'target_project_id' => project.id,
        'author_id' => admin.id,
        'assignee_id' => admin.id,
        'updated_by_id' => admin.id,
        'title' => "MR1",
        'created_at' => "2016-06-14T15:02:36.568Z",
        'updated_at' => "2016-06-14T15:02:56.815Z",
        'state' => "opened",
        'merge_status' => "unchecked",
        'description' => "I said to @sam the code should follow @bob's advice. @alice?",
        'position' => 0,
        'source_branch_sha' => "ABCD",
        'target_branch_sha' => "DCBA",
        'merge_when_pipeline_succeeds' => true
      }
    end

    it 'has preloaded author' do
      expect(created_object.author).to equal(admin)
    end

    it 'has preloaded updated_by' do
      expect(created_object.updated_by).to equal(admin)
    end

    it 'has preloaded source project' do
      expect(created_object.source_project).to equal(project)
    end

    it 'has preloaded target project' do
      expect(created_object.target_project).to equal(project)
    end

    it 'has auto merge set to false' do
      expect(created_object.merge_when_pipeline_succeeds).to eq(false)
    end

    it 'inserts backticks around username mentions' do
      expect(created_object.description).to eq("I said to `@sam` the code should follow `@bob`'s advice. `@alice`?")
    end
  end

  context 'issue object' do
    let(:relation_sym) { :issues }

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
          "id" => admin.id,
          "public_email" => admin.email,
          "username" => admin.username
        }
      }
    end

    let(:members_mapper) do
      Gitlab::ImportExport::MembersMapper.new(
        exported_members: [exported_member],
        user: importer_user,
        importable: project)
    end

    let(:relation_hash) do
      {
        'id' => 20,
        'target_branch' => "feature",
        'source_branch' => "feature_conflict",
        'project_id' => project.id,
        'author_id' => admin.id,
        'assignee_id' => admin.id,
        'updated_by_id' => admin.id,
        'title' => "Issue 1",
        'created_at' => "2016-06-14T15:02:36.568Z",
        'updated_at' => "2016-06-14T15:02:56.815Z",
        'state' => "opened",
        'description' => "I said to @sam the code should follow @bob's advice. @alice?",
        "relative_position" => 25111 # just a random position
      }
    end

    it 'has preloaded project' do
      expect(created_object.project).to equal(project)
    end

    context 'computing relative position' do
      context 'when max relative position in the hierarchy is not cached' do
        it 'has computed new relative_position' do
          expect(created_object.relative_position).to equal(1026) # 513*2 - ideal distance
        end
      end

      context 'when max relative position in the hierarchy is cached' do
        before do
          Rails.cache.write("import:#{project.model_name.plural}:#{project.id}:hierarchy_max_issues_relative_position", 10000)
        end

        it 'has computed new relative_position' do
          expect(created_object.relative_position).to equal(10000 + 1026) # 513*2 - ideal distance
        end
      end
    end

    context 'when issue_type is provided in the hash' do
      let(:additional_relation_attributes) { { 'issue_type' => 'task' } }

      it 'sets the correct work_item_type' do
        expect(created_object.work_item_type).to eq(WorkItems::Type.default_by_type(:task))
      end

      context 'when the provided issue_type is invalid' do
        let(:additional_relation_attributes) { { 'issue_type' => 'invalid_type' } }

        it 'does not set a work item type, lets the model default to issue' do
          expect(created_object.work_item_type).to be_nil
        end
      end
    end

    context 'when work_item_type is provided in the hash' do
      let(:incident_type) { WorkItems::Type.default_by_type(:incident) }
      let(:additional_relation_attributes) { { 'work_item_type' => incident_type } }

      it 'sets the correct work_item_type' do
        expect(created_object.work_item_type).to eq(incident_type)
      end
    end

    context 'when issue_type is provided in the hash as well as a work_item_type' do
      let(:incident_type) { WorkItems::Type.default_by_type(:incident) }
      let(:additional_relation_attributes) do
        { 'issue_type' => 'task', 'work_item_type' => incident_type }
      end

      it 'makes work_item_type take precedence over issue_type' do
        expect(created_object.work_item_type).to eq(incident_type)
      end
    end

    it 'inserts backticks around username mentions' do
      expect(created_object.description).to eq("I said to `@sam` the code should follow `@bob`'s advice. `@alice`?")
    end
  end

  context 'label object' do
    let(:relation_sym) { :labels }
    let(:relation_hash) do
      {
        id: 3,
        title: "test3",
        color: "#428bca",
        group_id: project.group.id,
        created_at: "2016-07-22T08:55:44.161Z",
        updated_at: "2016-07-22T08:55:44.161Z",
        template: false,
        description: "",
        project_id: project.id,
        type: "GroupLabel"
      }
    end

    it 'has preloaded project' do
      expect(created_object.project).to equal(project)
    end

    it 'has preloaded group' do
      expect(created_object.group).to equal(project.group)
    end
  end

  context 'pipeline setup' do
    let(:relation_sym) { :ci_pipelines }
    let(:relation_hash) do
      {
        "id" => 1,
        "status" => status
      }
    end

    subject { created_object }

    ::Ci::HasStatus::COMPLETED_STATUSES.each do |status|
      context "when relation_hash has a completed status of #{status}}" do
        let(:status) { status }

        it "does not change the created object status" do
          expect(created_object.status).to eq(status)
        end
      end
    end

    ::Ci::HasStatus::CANCELABLE_STATUSES.each do |status|
      context "when relation_hash has cancelable status of #{status}}" do
        let(:status) { status }

        it "sets the created object status to canceled" do
          expect(created_object.status).to eq('canceled')
        end
      end
    end
  end

  context 'pipeline_schedule' do
    let(:relation_sym) { :pipeline_schedules }
    let(:value) { true }
    let(:relation_hash) do
      {
        'id' => 3,
        'created_at' => '2016-07-22T08:55:44.161Z',
        'updated_at' => '2016-07-22T08:55:44.161Z',
        'description' => 'pipeline schedule',
        'ref' => 'main',
        'cron' => '0 4 * * 0',
        'cron_timezone' => 'UTC',
        'active' => value,
        'project_id' => project.id,
        'owner_id' => non_existing_record_id
      }
    end

    subject { created_object.active }

    [true, false].each do |v|
      context "when relation_hash has active set to #{v}" do
        let(:value) { v }

        it "the created object is not active" do
          expect(created_object.active).to eq(false)
        end
      end
    end

    it 'sets importer user as owner' do
      expect(created_object.owner_id).to eq(importer_user.id)
    end
  end

  # `project_id`, `described_class.USER_REFERENCES`, noteable_id, target_id, and some project IDs are already
  # re-assigned by described_class.
  context 'Potentially hazardous foreign keys' do
    let(:dummy_int) { project.id + 1 } # to avoid setting an integer that equals the current project.id
    let(:relation_sym) { :hazardous_foo_model }
    let(:relation_hash) do
      {
        'integration_id' => dummy_int,
        'moved_to_id' => dummy_int,
        'namespace_id' => dummy_int,
        'ci_id' => dummy_int,
        'random_project_id' => dummy_int,
        'random_id' => dummy_int,
        'milestone_id' => dummy_int,
        'project_id' => dummy_int,
        'user_id' => dummy_int
      }
    end

    before do
      stub_const('HazardousFooModel', Class.new(FooModel))
      HazardousFooModel.class_eval do
        attr_accessor :integration_id, :moved_to_id, :namespace_id, :ci_id, :random_project_id, :random_id, :milestone_id, :project_id
      end

      allow(HazardousFooModel).to receive(:reflect_on_association).and_return(nil)
    end

    it 'does not preserve any foreign key IDs' do
      expect(created_object.values).to match_array([created_object.project_id])
    end
  end

  context 'overrided model with pluralized name' do
    let(:dummy_int) { project.id + 1 } # to avoid setting an integer that equals the current project.id
    let(:relation_sym) { :metrics }

    let(:relation_hash) do
      {
        'id' => dummy_int,
        'merge_request_id' => dummy_int,
        'merged_at' => Time.now,
        'merged_by_id' => dummy_int,
        'latest_closed_at' => nil,
        'latest_closed_by_id' => nil
      }
    end

    it 'does not raise errors' do
      expect { created_object }.not_to raise_error
    end
  end

  context 'Project references' do
    let(:dummy_int) { project.id + 1 } # to avoid setting an integer that equals the current project.id
    let(:relation_sym) { :project_foo_model }
    let(:relation_hash) do
      Gitlab::ImportExport::Project::RelationFactory::PROJECT_REFERENCES.map { |ref| { ref => dummy_int } }.inject(:merge)
    end

    before do
      stub_const('ProjectFooModel', Class.new(FooModel))
      ProjectFooModel.class_eval do
        attr_accessor(*Gitlab::ImportExport::Project::RelationFactory::PROJECT_REFERENCES)
      end

      allow(ProjectFooModel).to receive(:reflect_on_association).and_return(nil)
    end

    it 'does not preserve any project foreign key IDs' do
      expect(created_object.values).not_to include(dummy_int)
    end
  end

  it_behaves_like 'Notes user references' do
    let(:importable) { project }
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

  context 'event object' do
    let(:relation_sym) { :events }
    let(:relation_hash) do
      {
        'project_id' => project.id,
        'author_id' => admin.id,
        'action' => 'created',
        'target_type' => 'Issue'
      }
    end

    it 'has preloaded project' do
      expect(created_object.project).to equal(project)
    end

    it 'builds an event' do
      expect(created_object).to be_an(Event)
    end

    context 'when user ID maps to no user' do
      let(:members_mapper) { double('members_mapper', map: {}) }

      it 'does not build an event' do
        expect(created_object).to be_nil
      end
    end
  end

  describe 'approval object' do
    let(:relation_sym) { :approvals }
    let(:relation_hash) do
      {
        'user_id' => admin.id
      }
    end

    it 'builds an approvals' do
      expect(created_object).to be_an(Approval)
    end

    context 'when user ID maps to no user' do
      let(:members_mapper) { double('members_mapper', map: {}) }

      it 'does not build an approval' do
        expect(created_object).to be_nil
      end
    end
  end

  describe 'protected refs access levels' do
    shared_examples 'access levels' do
      let(:relation_hash) { { 'access_level' => access_level, 'created_at' => '2022-03-29T09:53:13.457Z', 'updated_at' => '2022-03-29T09:54:13.457Z' } }

      context 'when access level is no one' do
        let(:access_level) { Gitlab::Access::NO_ACCESS }

        it 'keeps no one access level' do
          expect(created_object.access_level).to equal(access_level)
        end
      end

      context 'when access level is below maintainer' do
        let(:access_level) { Gitlab::Access::DEVELOPER }

        it 'sets access level to maintainer' do
          expect(created_object.access_level).to equal(Gitlab::Access::MAINTAINER)
        end
      end

      context 'when access level is above maintainer' do
        let(:access_level) { Gitlab::Access::OWNER }

        it 'sets access level to maintainer' do
          expect(created_object.access_level).to equal(Gitlab::Access::MAINTAINER)
        end
      end

      describe 'root ancestor membership' do
        let(:access_level) { Gitlab::Access::DEVELOPER }

        context 'when importer user is root group owner' do
          let(:importer_user) { create(:user) }

          it 'keeps access level as is' do
            group.add_owner(importer_user)

            expect(created_object.access_level).to equal(access_level)
          end
        end

        context 'when user membership in root group is missing' do
          it 'sets access level to maintainer' do
            group.members.delete_all

            expect(created_object.access_level).to equal(Gitlab::Access::MAINTAINER)
          end
        end

        context 'when root ancestor is not a group' do
          it 'sets access level to maintainer' do
            expect(created_object.access_level).to equal(Gitlab::Access::MAINTAINER)
          end
        end
      end
    end

    describe 'protected branch access levels' do
      context 'merge access level' do
        let(:relation_sym) { :'ProtectedBranch::MergeAccessLevel' }

        include_examples 'access levels'
      end

      context 'push access level' do
        let(:relation_sym) { :'ProtectedBranch::PushAccessLevel' }

        include_examples 'access levels'
      end
    end

    describe 'protected tag access levels' do
      context 'create access level' do
        let(:relation_sym) { :'ProtectedTag::CreateAccessLevel' }

        include_examples 'access levels'
      end
    end
  end

  describe 'diff notes' do
    context 'when relation is a diff note' do
      let(:relation_sym) { :notes }
      let(:line_range) do
        {
          "line_range" => {
            "start_line_code" => "abc_0_1",
            "start_line_type" => "new",
            "end_line_code" => "abc_5_10",
            "end_line_type" => "new"
          }
        }
      end

      let(:relation_hash) do
        {
          'note' => 'note',
          'noteable_type' => 'MergeRequest',
          'type' => 'DiffNote',
          'position' => line_range,
          'original_position' => line_range,
          'change_position' => line_range
        }
      end

      context 'when diff note line_range is in an outdated format' do
        it 'updates the line_range to the new format' do
          expect_next_instance_of(described_class) do |relation_factory|
            expect(relation_factory).to receive(:setup_models).and_call_original
          end

          expected_line_range = {
            'start' => {
              'line_code' => 'abc_0_1',
              'type' => 'new',
              'old_line' => nil,
              'new_line' => 1
            },
            'end' => {
              'line_code' => 'abc_5_10',
              'type' => 'new',
              'old_line' => 5,
              'new_line' => 10
            }
          }

          expect(created_object.position.line_range).to eq(expected_line_range)
          expect(created_object.original_position.line_range).to eq(expected_line_range)
          expect(created_object.change_position.line_range).to eq(expected_line_range)
        end
      end
    end
  end

  describe 'note diff files' do
    let(:relation_sym) { :note_diff_file }
    let(:relation_hash) do
      {
        'diff' => 'diff',
        'new_file' => true,
        'renamed_file' => false,
        'deleted_file' => false,
        'a_mode' => '100644',
        'b_mode' => '100644',
        'new_path' => 'new_path',
        'old_path' => 'old_path',
        'diff_export' => 'diff_export'
      }
    end

    it 'sets diff to diff_export value' do
      expect(created_object.diff).to eq('diff_export')
    end

    context 'when diff_export contains null bytes' do
      let(:relation_hash) do
        {
          'new_file' => true,
          'renamed_file' => false,
          'deleted_file' => false,
          'a_mode' => '100644',
          'b_mode' => '100644',
          'new_path' => 'new_path',
          'old_path' => 'old_path',
          'diff_export' => "diff_export\x00"
        }
      end

      it 'removes the null bytes' do
        expect(created_object.diff).to eq('diff_export')
      end
    end
  end
end
