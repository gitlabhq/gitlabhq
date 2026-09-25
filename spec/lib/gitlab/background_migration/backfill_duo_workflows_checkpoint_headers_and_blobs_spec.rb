# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDuoWorkflowsCheckpointHeadersAndBlobs,
  feature_category: :duo_agent_platform do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }
  let(:workflows) { table(:duo_workflows_workflows) }
  # let!: the helper creates the partitions, and the job inserts into headers and
  # blobs before most examples reference them.
  let!(:checkpoints) { partitioned_table(:p_duo_workflows_checkpoints, by: :created_at, strategy: :daily) }
  let!(:headers) { partitioned_table(:p_duo_workflows_checkpoint_headers, by: :workflow_created_at, strategy: :daily) }
  let!(:blobs) { partitioned_table(:p_duo_workflows_checkpoint_blobs, by: :workflow_created_at, strategy: :daily) }

  let(:organization) { organizations.create!(name: 'Org', path: 'org') }
  let(:group_namespace) { namespaces.create!(name: 'Group', path: 'group', organization_id: organization.id) }
  let(:project_namespace) do
    namespaces.create!(name: 'Project NS', path: 'project-ns', organization_id: organization.id)
  end

  let(:project) do
    projects.create!(
      namespace_id: group_namespace.id, project_namespace_id: project_namespace.id, organization_id: organization.id
    )
  end

  let(:user) do
    users.create!(email: 'u@example.com', projects_limit: 10, username: 'u', organization_id: organization.id)
  end

  let(:workflow) { create_workflow(created_at: 2.days.ago) }

  let(:channel_values) do
    {
      'status' => 'Execution',
      'ui_chat_log' => [{ 'message_id' => 'm1', 'content' => 'hi' }],
      'plan' => { 'steps' => [{ 'id' => 's1' }] }
    }
  end

  let(:checkpoint_payload) do
    {
      'v' => 1,
      'channel_versions' => { 'status' => 2, 'ui_chat_log' => 3, 'plan' => 1 },
      'versions_seen' => {},
      'channel_values' => channel_values
    }
  end

  let!(:legacy_checkpoint) do
    create_checkpoint(workflow, thread_ts: 'ts-1', parent_ts: 'ts-0', checkpoint_ns: 'delegation:1', current_thread: 2)
  end

  def create_workflow(created_at: Time.current)
    workflows.create!(project_id: project.id, user_id: user.id, goal: 'goal', created_at: created_at)
  end

  def create_checkpoint(workflow, thread_ts:, checkpoint: checkpoint_payload, **attrs)
    checkpoints.create!(
      workflow_id: workflow.id, project_id: workflow.project_id, namespace_id: workflow.namespace_id,
      thread_ts: thread_ts, checkpoint: checkpoint, metadata: { 'source' => 'loop', 'step' => 1 }, **attrs
    )
  end

  def create_header(checkpoint, workflow)
    headers.create!(
      workflow_id: workflow.id, project_id: project.id, workflow_created_at: workflow.created_at,
      thread_ts: checkpoint.thread_ts, checkpoint: {}, metadata: {}, channel_keys: []
    )
  end

  def perform_migration(
    start_cursor: [checkpoints.minimum(:id), checkpoints.minimum(:created_at)],
    end_cursor: [checkpoints.maximum(:id), checkpoints.maximum(:created_at)]
  )
    described_class.new(
      start_cursor: start_cursor,
      end_cursor: end_cursor,
      batch_table: :p_duo_workflows_checkpoints,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    ).perform
  end

  def decode(blob)
    Gitlab::Json::SafeParser.parse(Zlib::Inflate.inflate(blob.data))
  end

  describe '#perform' do
    it 'writes a slim header for the legacy row', :aggregate_failures do
      perform_migration

      header = headers.find_by!(workflow_id: workflow.id, thread_ts: 'ts-1')

      expect(header).to have_attributes(
        project_id: project.id,
        namespace_id: nil,
        parent_ts: 'ts-0',
        checkpoint_ns: 'delegation:1',
        current_thread: 2,
        checkpoint: checkpoint_payload.except('channel_values'),
        metadata: { 'source' => 'loop', 'step' => 1 },
        channel_keys: match_array(%w[status ui_chat_log plan])
      )
      expect(header.workflow_created_at).to be_within(1.second).of(workflow.created_at)
      expect(header.created_at).to be_within(1.second).of(legacy_checkpoint.created_at)
    end

    it 'writes one compaction blob per channel holding the full channel value', :aggregate_failures do
      perform_migration

      written = blobs.where(workflow_id: workflow.id, thread_ts: 'ts-1').index_by(&:channel)

      expect(written.keys).to match_array(%w[status ui_chat_log plan])
      expect(written.transform_values { |blob| decode(blob) }).to eq(channel_values)
      expect(written.values).to all(have_attributes(
        project_id: project.id,
        current_thread: 2,
        version: legacy_checkpoint.id.to_s,
        write_type: 'json',
        step_action: 'compaction'
      ))
      expect(written['status'].workflow_created_at).to be_within(1.second).of(workflow.created_at)
    end

    it 'skips rows that already have a header' do
      dual_written = create_checkpoint(workflow, thread_ts: 'ts-2')
      create_header(dual_written, workflow)

      perform_migration

      expect(headers.where(workflow_id: workflow.id, thread_ts: 'ts-2').count).to eq(1)
      expect(blobs.where(workflow_id: workflow.id, thread_ts: 'ts-2')).to be_empty
    end

    it 'migrates rows across workflows and sub-batches', :aggregate_failures do
      other_workflow = create_workflow
      create_checkpoint(workflow, thread_ts: 'ts-2')
      create_checkpoint(other_workflow, thread_ts: 'ts-1')

      perform_migration

      expect(headers.where(workflow_id: workflow.id).pluck(:thread_ts)).to match_array(%w[ts-1 ts-2])
      expect(headers.where(workflow_id: other_workflow.id).pluck(:thread_ts)).to eq(%w[ts-1])
      expect(blobs.count).to eq(9)
    end

    it 'stops at the end cursor' do
      later = create_checkpoint(workflow, thread_ts: 'ts-2')

      perform_migration(end_cursor: [legacy_checkpoint.id, legacy_checkpoint.created_at])

      expect(headers.where(thread_ts: later.thread_ts)).to be_empty
    end

    it 'is idempotent' do
      perform_migration

      expect { perform_migration }.to not_change { headers.count }.and(not_change { blobs.count })
    end

    it 'writes an empty membership and no blobs for a checkpoint without channel_values' do
      bare = create_checkpoint(workflow, thread_ts: 'ts-2', checkpoint: { 'v' => 1 })

      # Only this row in the batch, so the sub-batch has a header to insert and no blobs.
      perform_migration(start_cursor: [bare.id, bare.created_at], end_cursor: [bare.id, bare.created_at])

      expect(headers.find_by!(thread_ts: bare.thread_ts).channel_keys).to eq([])
      expect(blobs.where(thread_ts: bare.thread_ts)).to be_empty
      expect(headers.where(thread_ts: 'ts-1')).to be_empty
    end

    it 'skips and logs a checkpoint with more channels than a header can record', :aggregate_failures do
      wide = Array.new(described_class::CHANNEL_KEYS_LIMIT + 1) { |i| ["channel_#{i}", i] }.to_h
      over_cap = create_checkpoint(workflow, thread_ts: 'ts-2', checkpoint: { 'channel_values' => wide })

      expect(Gitlab::BackgroundMigration::Logger).to receive(:warn).with(
        hash_including(checkpoint_id: over_cap.id, channels: wide.size)
      ).and_call_original

      perform_migration

      expect(headers.where(thread_ts: 'ts-2')).to be_empty
      expect(blobs.where(thread_ts: 'ts-2')).to be_empty
      expect(headers.where(thread_ts: 'ts-1').count).to eq(1)
    end

    it 'skips rows of a workflow older than the header retention window', :aggregate_failures do
      old_workflow = create_workflow(created_at: (described_class::RETENTION + 1.day).ago)
      create_checkpoint(old_workflow, thread_ts: 'ts-1')

      perform_migration

      expect(headers.where(workflow_id: old_workflow.id)).to be_empty
      expect(headers.where(workflow_id: workflow.id).count).to eq(1)
    end

    it 'writes both rows of a re-sent thread_ts in legacy order when they share a sub-batch',
      :aggregate_failures do
      re_sent = create_checkpoint(workflow, thread_ts: 'ts-1', checkpoint: checkpoint_payload.merge('v' => 2))

      perform_migration

      expect(headers.where(thread_ts: 'ts-1').order(:id).pluck(:checkpoint).pluck('v')).to eq([1, 2])
      expect(blobs.where(thread_ts: 'ts-1', channel: 'status').order(:id).pluck(:version))
        .to eq([legacy_checkpoint.id.to_s, re_sent.id.to_s])
    end

    it 'skips a re-sent thread_ts once an earlier sub-batch wrote its header', :aggregate_failures do
      # sub_batch_size is 2: the filler pushes the re-sent row into the next sub-batch.
      create_checkpoint(workflow, thread_ts: 'ts-2')
      create_checkpoint(workflow, thread_ts: 'ts-1', checkpoint: checkpoint_payload.merge('v' => 2))

      perform_migration

      expect(headers.where(thread_ts: 'ts-1').pluck(:checkpoint).pluck('v')).to eq([1])
      expect(blobs.where(thread_ts: 'ts-1', channel: 'status').pluck(:version)).to eq([legacy_checkpoint.id.to_s])
    end

    it 'copies the sharding key of a namespace-level workflow', :aggregate_failures do
      group_workflow = workflows.create!(
        namespace_id: group_namespace.id, user_id: user.id, goal: 'goal', created_at: 1.day.ago
      )
      create_checkpoint(group_workflow, thread_ts: 'ts-1')

      perform_migration

      header = headers.find_by!(workflow_id: group_workflow.id)
      expect(header).to have_attributes(project_id: nil, namespace_id: group_namespace.id)
      expect(blobs.where(workflow_id: group_workflow.id).pluck(:namespace_id).uniq).to eq([group_namespace.id])
      expect(blobs.where(workflow_id: group_workflow.id).count).to eq(3)
    end

    it 'writes an empty header for a checkpoint that is not a JSON object', :aggregate_failures do
      odd = create_checkpoint(workflow, thread_ts: 'ts-2', checkpoint: %w[not an object])

      perform_migration

      header = headers.find_by!(thread_ts: odd.thread_ts)
      expect(header.checkpoint).to eq({})
      expect(header.channel_keys).to eq([])
      expect(blobs.where(thread_ts: odd.thread_ts)).to be_empty
    end

    it 'skips a blob over the size limit and logs it', :aggregate_failures do
      stub_const("#{described_class}::BLOB_DATA_LIMIT", 20)

      expect(Gitlab::BackgroundMigration::Logger).to receive(:warn).with(
        hash_including(checkpoint_id: legacy_checkpoint.id, channel: 'ui_chat_log')
      ).and_call_original
      expect(Gitlab::BackgroundMigration::Logger).to receive(:warn).with(
        hash_including(checkpoint_id: legacy_checkpoint.id, channel: 'plan')
      ).and_call_original

      perform_migration

      expect(blobs.where(thread_ts: 'ts-1').pluck(:channel)).to eq(%w[status])
      expect(headers.find_by!(thread_ts: 'ts-1').channel_keys).to match_array(%w[status ui_chat_log plan])
    end
  end
end
