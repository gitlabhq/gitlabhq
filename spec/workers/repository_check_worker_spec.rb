require 'spec_helper'

describe RepositoryCheckWorker do
  subject { RepositoryCheckWorker.new }

  it 'prefers projects that have never been checked' do
    projects = 3.times.map { create(:project) }
    projects[0].update_column(:last_repository_check_at, 1.month.ago)
    projects[2].update_column(:last_repository_check_at, 3.weeks.ago)

    expect(subject.perform).to eq(projects.values_at(1, 0, 2).map(&:id))
  end

  it 'sorts projects by last_repository_check_at' do
    projects = 3.times.map { create(:project) }
    projects[0].update_column(:last_repository_check_at, 2.weeks.ago)
    projects[1].update_column(:last_repository_check_at, 1.month.ago)
    projects[2].update_column(:last_repository_check_at, 3.weeks.ago)

    expect(subject.perform).to eq(projects.values_at(1, 2, 0).map(&:id))
  end

  it 'excludes projects that were checked recently' do
    projects = 3.times.map { create(:project) }
    projects[0].update_column(:last_repository_check_at, 2.days.ago)
    projects[1].update_column(:last_repository_check_at, 1.month.ago)
    projects[2].update_column(:last_repository_check_at, 3.days.ago)

    expect(subject.perform).to eq([projects[1].id])
  end

  it 'does nothing when repository checks are disabled' do
    create(:empty_project)
    current_settings = double('settings', repository_checks_enabled: false)
    expect(subject).to receive(:current_settings) { current_settings }

    expect(subject.perform).to eq(nil)
  end
end
