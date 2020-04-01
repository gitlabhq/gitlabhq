# frozen_string_literal: true

# Shared examples for Project::TreeRestorer (shared to allow the testing
# of EE-specific features)
RSpec.shared_examples 'restores project successfully' do |**results|
  it 'restores the project' do
    expect(shared.errors).to be_empty
    expect(restored_project_json).to be_truthy
  end

  it 'has labels' do
    labels_size = results.fetch(:labels, 0)

    expect(project.labels.size).to eq(labels_size)
  end

  it 'has label priorities' do
    label_with_priorities = results[:label_with_priorities]

    if label_with_priorities
      expect(project.labels.find_by(title: label_with_priorities).priorities).not_to be_empty
    end
  end

  it 'has milestones' do
    expect(project.milestones.size).to eq(results.fetch(:milestones, 0))
  end

  it 'has issues' do
    expect(project.issues.size).to eq(results.fetch(:issues, 0))
  end

  it 'has ci pipelines' do
    expect(project.ci_pipelines.size).to eq(results.fetch(:ci_pipelines, 0))
  end

  it 'has external pull requests' do
    expect(project.external_pull_requests.size).to eq(results.fetch(:external_pull_requests, 0))
  end

  it 'does not set params that are excluded from import_export settings' do
    expect(project.import_type).to be_nil
    expect(project.creator_id).not_to eq non_existing_record_id
  end

  it 'records exact number of import failures' do
    expect(project.import_failures.size).to eq(results.fetch(:import_failures, 0))
  end
end
