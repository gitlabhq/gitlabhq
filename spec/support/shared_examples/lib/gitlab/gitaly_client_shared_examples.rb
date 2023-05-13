# frozen_string_literal: true

def raw_repo_without_container(repository)
  Gitlab::Git::Repository.new(
    repository.shard,
    "#{repository.disk_path}.git",
    repository.repo_type.identifier_for_container(repository.container),
    repository.container.full_path
  )
end

RSpec.shared_examples 'Gitaly feature flag actors are inferred from repository' do
  it 'captures correct actors' do
    service.repository_actor = repository

    expect(service.repository_actor.flipper_id).to eql(repository.flipper_id)

    if expected_project.nil?
      expect(service.project_actor).to be(nil)
    else
      expect(service.project_actor.flipper_id).to eql(expected_project.flipper_id)
    end

    if expected_group.nil?
      expect(service.group_actor).to be(nil)
    else
      expect(service.group_actor.flipper_id).to eql(expected_group.flipper_id)
    end
  end

  it 'does not issues SQL queries after the first invocation' do
    service.repository_actor = repository

    service.repository_actor
    service.project_actor
    service.group_actor

    recorder = ActiveRecord::QueryRecorder.new do
      3.times do
        service.repository_actor
        service.project_actor
        service.group_actor
      end
    end

    expect(recorder.count).to be(0)
  end
end
