require 'spec_helper'

describe RepositoryCheck::BatchWorker do
  subject { described_class.new }

  it 'prefers projects that have never been checked' do
    projects = create_list(:project, 3)
    projects[0].update_column(:last_repository_check_at, 4.months.ago)
    projects[2].update_column(:last_repository_check_at, 3.months.ago)

    expect(subject.perform).to eq(projects.values_at(1, 0, 2).map(&:id))
  end

  it 'sorts projects by last_repository_check_at' do
    projects = create_list(:project, 3)
    projects[0].update_column(:last_repository_check_at, 2.months.ago)
    projects[1].update_column(:last_repository_check_at, 4.months.ago)
    projects[2].update_column(:last_repository_check_at, 3.months.ago)

    expect(subject.perform).to eq(projects.values_at(1, 2, 0).map(&:id))
  end

  it 'excludes projects that were checked recently' do
    projects = create_list(:project, 3)
    projects[0].update_column(:last_repository_check_at, 2.days.ago)
    projects[1].update_column(:last_repository_check_at, 2.months.ago)
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
