# frozen_string_literal: true

require 'spec_helper'

describe RepositoryCheck::BatchWorker do
  let(:shard_name) { 'default' }

  subject { described_class.new }

  before do
    Gitlab::ShardHealthCache.update([shard_name])
  end

  it 'prefers projects that have never been checked' do
    projects = create_list(:project, 3, created_at: 1.week.ago)
    projects[0].update_column(:last_repository_check_at, 4.months.ago)
    projects[2].update_column(:last_repository_check_at, 3.months.ago)

    expect(subject.perform(shard_name)).to eq(projects.values_at(1, 0, 2).map(&:id))
  end

  it 'sorts projects by last_repository_check_at' do
    projects = create_list(:project, 3, created_at: 1.week.ago)
    projects[0].update_column(:last_repository_check_at, 2.months.ago)
    projects[1].update_column(:last_repository_check_at, 4.months.ago)
    projects[2].update_column(:last_repository_check_at, 3.months.ago)

    expect(subject.perform(shard_name)).to eq(projects.values_at(1, 2, 0).map(&:id))
  end

  it 'excludes projects that were checked recently' do
    projects = create_list(:project, 3, created_at: 1.week.ago)
    projects[0].update_column(:last_repository_check_at, 2.days.ago)
    projects[1].update_column(:last_repository_check_at, 2.months.ago)
    projects[2].update_column(:last_repository_check_at, 3.days.ago)

    expect(subject.perform(shard_name)).to eq([projects[1].id])
  end

  it 'excludes projects on another shard' do
    projects = create_list(:project, 2, created_at: 1.week.ago)
    projects[0].update_column(:repository_storage, 'other')

    expect(subject.perform(shard_name)).to eq([projects[1].id])
  end

  it 'does nothing when repository checks are disabled' do
    create(:project, created_at: 1.week.ago)

    stub_application_setting(repository_checks_enabled: false)

    expect(subject.perform(shard_name)).to eq(nil)
  end

  it 'does nothing when shard is unhealthy' do
    shard_name = 'broken'
    create(:project, :broken_storage, created_at: 1.week.ago)

    expect(subject.perform(shard_name)).to eq(nil)
  end

  it 'skips projects created less than 24 hours ago' do
    project = create(:project)
    project.update_column(:created_at, 23.hours.ago)

    expect(subject.perform(shard_name)).to eq([])
  end

  it 'does not run if the exclusive lease is taken' do
    allow(subject).to receive(:try_obtain_lease).and_return(false)

    expect(subject).not_to receive(:perform_repository_checks)

    subject.perform(shard_name)
  end
end
