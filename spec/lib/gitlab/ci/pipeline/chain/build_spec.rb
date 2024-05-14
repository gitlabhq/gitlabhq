# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Build do
  let_it_be(:project, reload: true) { create(:project, :repository) }
  let_it_be(:user) { create(:user, developer_of: project) }

  let(:pipeline) { Ci::Pipeline.new }

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      source: :push,
      origin_ref: 'master',
      checkout_sha: project.commit.id,
      after_sha: nil,
      before_sha: nil,
      trigger_request: nil,
      schedule: nil,
      merge_request: nil,
      project: project,
      current_user: user)
  end

  let(:step) { described_class.new(pipeline, command) }

  it 'does not break the chain' do
    step.perform!

    expect(step.break?).to be false
  end

  it 'builds a pipeline with the expected attributes' do
    step.perform!

    expect(pipeline.sha).not_to be_empty
    expect(pipeline.sha).to eq project.commit.id
    expect(pipeline.ref).to eq 'master'
    expect(pipeline.tag).to be false
    expect(pipeline.user).to eq user
    expect(pipeline.project).to eq project
  end

  it 'returns a valid pipeline' do
    step.perform!

    expect(pipeline).to be_valid
  end

  it 'does not persist a pipeline' do
    step.perform!

    expect(pipeline).not_to be_persisted
  end

  context 'when pipeline is running for a tag' do
    let(:command) do
      Gitlab::Ci::Pipeline::Chain::Command.new(
        source: :push,
        origin_ref: origin_ref,
        checkout_sha: project.commit.id,
        after_sha: nil,
        before_sha: nil,
        trigger_request: nil,
        schedule: nil,
        merge_request: nil,
        project: project,
        current_user: user)
    end

    let(:origin_ref) { 'mytag' }

    before do
      allow_any_instance_of(Repository).to receive(:tag_exists?).with('mytag').and_return(true)

      step.perform!
    end

    it 'correctly indicated that this is a tagged pipeline' do
      expect(pipeline).to be_tag
    end

    context 'when origin_ref is branch but tag ref with the same name exists' do
      let(:origin_ref) { 'refs/heads/mytag' }

      it 'correctly indicated that a pipeline is not tagged' do
        expect(pipeline).not_to be_tag
      end
    end
  end

  context 'when pipeline is running for a merge request' do
    let(:command) do
      Gitlab::Ci::Pipeline::Chain::Command.new(
        source: :merge_request_event,
        origin_ref: 'feature',
        checkout_sha: project.commit.id,
        after_sha: nil,
        before_sha: nil,
        source_sha: merge_request.diff_head_sha,
        target_sha: merge_request.target_branch_sha,
        trigger_request: nil,
        schedule: nil,
        merge_request: merge_request,
        project: project,
        current_user: user)
    end

    let(:merge_request) { build(:merge_request, target_project: project) }

    before do
      step.perform!
    end

    it 'correctly indicated that this is a merge request pipeline' do
      expect(pipeline).to be_merge_request_event
      expect(pipeline.merge_request).to eq(merge_request)
    end

    it 'correctly sets souce sha and target sha to pipeline' do
      expect(pipeline.source_sha).to eq(merge_request.diff_head_sha)
      expect(pipeline.target_sha).to eq(merge_request.target_branch_sha)
    end
  end

  context 'when pipeline is running for an external pull request' do
    let(:command) do
      Gitlab::Ci::Pipeline::Chain::Command.new(
        source: :external_pull_request_event,
        origin_ref: 'feature',
        checkout_sha: project.commit.id,
        after_sha: nil,
        before_sha: nil,
        source_sha: external_pull_request.source_sha,
        target_sha: external_pull_request.target_sha,
        trigger_request: nil,
        schedule: nil,
        external_pull_request: external_pull_request,
        project: project,
        current_user: user)
    end

    let(:external_pull_request) { build(:external_pull_request, project: project) }

    before do
      step.perform!
    end

    it 'correctly indicated that this is an external pull request pipeline' do
      expect(pipeline).to be_external_pull_request_event
      expect(pipeline.external_pull_request).to eq(external_pull_request)
    end

    it 'correctly sets source sha and target sha to pipeline' do
      expect(pipeline.source_sha).to eq(external_pull_request.source_sha)
      expect(pipeline.target_sha).to eq(external_pull_request.target_sha)
    end
  end

  context 'when keep_latest_artifact is set' do
    using RSpec::Parameterized::TableSyntax

    where(:keep_latest_artifact, :locking_result) do
      true          | 'artifacts_locked'
      false         | 'unlocked'
    end

    with_them do
      before do
        project.update!(keep_latest_artifact: keep_latest_artifact)
      end

      it 'builds a pipeline with appropriate locked value' do
        step.perform!

        expect(pipeline.locked).to eq(locking_result)
      end
    end
  end
end
