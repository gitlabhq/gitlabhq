# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BatchingStrategies::DismissedVulnerabilitiesStrategy, '#next_batch' do
  let(:batching_strategy) { described_class.new(connection: ActiveRecord::Base.connection) }
  let(:namespace) { table(:namespaces).create!(name: 'user', path: 'user') }
  let(:users) { table(:users) }
  let(:user) { create_user! }
  let(:project) do
    table(:projects).create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      packages_enabled: false)
  end

  let(:vulnerabilities) { table(:vulnerabilities) }

  let!(:vulnerability1) do
    create_vulnerability!(
      project_id: project.id,
      author_id: user.id,
      dismissed_at: Time.current
    )
  end

  let!(:vulnerability2) do
    create_vulnerability!(
      project_id: project.id,
      author_id: user.id,
      dismissed_at: Time.current
    )
  end

  let!(:vulnerability3) do
    create_vulnerability!(
      project_id: project.id,
      author_id: user.id,
      dismissed_at: Time.current
    )
  end

  let!(:vulnerability4) do
    create_vulnerability!(
      project_id: project.id,
      author_id: user.id,
      dismissed_at: nil
    )
  end

  it { expect(described_class).to be < Gitlab::BackgroundMigration::BatchingStrategies::PrimaryKeyBatchingStrategy }

  context 'when starting on the first batch' do
    it 'returns the bounds of the next batch' do
      batch_bounds = batching_strategy.next_batch(
        :vulnerabilities,
        :id,
        batch_min_value: vulnerability1.id,
        batch_size: 2,
        job_arguments: []
      )
      expect(batch_bounds).to eq([vulnerability1.id, vulnerability2.id])
    end
  end

  context 'when additional batches remain' do
    it 'returns the bounds of the next batch and skips the records that do not have `dismissed_at` set' do
      batch_bounds = batching_strategy.next_batch(
        :vulnerabilities,
        :id,
        batch_min_value: vulnerability3.id,
        batch_size: 2,
        job_arguments: []
      )

      expect(batch_bounds).to eq([vulnerability3.id, vulnerability3.id])
    end
  end

  context 'when no additional batches remain' do
    it 'returns nil' do
      batch_bounds = batching_strategy.next_batch(
        :vulnerabilities,
        :id,
        batch_min_value: vulnerability4.id + 1,
        batch_size: 1,
        job_arguments: []
      )

      expect(batch_bounds).to be_nil
    end
  end

  private

  def create_vulnerability!(
    project_id:, author_id:, title: 'test', severity: 7, confidence: 7, report_type: 0, state: 1, dismissed_at: nil
  )
    vulnerabilities.create!(
      project_id: project_id,
      author_id: author_id,
      title: title,
      severity: severity,
      confidence: confidence,
      report_type: report_type,
      state: state,
      dismissed_at: dismissed_at
    )
  end

  def create_user!(name: "Example User", email: "user@example.com", user_type: nil)
    users.create!(
      name: name,
      email: email,
      username: name,
      projects_limit: 10
    )
  end
end
