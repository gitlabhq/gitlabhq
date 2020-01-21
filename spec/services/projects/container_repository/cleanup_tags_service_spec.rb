# frozen_string_literal: true

require 'spec_helper'

describe Projects::ContainerRepository::CleanupTagsService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:repository) { create(:container_repository, :root, project: project) }

  let(:service) { described_class.new(project, user, params) }

  before do
    project.add_maintainer(user)

    stub_feature_flags(container_registry_cleanup: true)

    stub_container_registry_config(enabled: true)

    stub_container_registry_tags(
      repository: repository.path,
      tags: %w(latest A Ba Bb C D E))

    stub_tag_digest('latest', 'sha256:configA')
    stub_tag_digest('A', 'sha256:configA')
    stub_tag_digest('Ba', 'sha256:configB')
    stub_tag_digest('Bb', 'sha256:configB')
    stub_tag_digest('C', 'sha256:configC')
    stub_tag_digest('D', 'sha256:configD')
    stub_tag_digest('E', nil)

    stub_digest_config('sha256:configA', 1.hour.ago)
    stub_digest_config('sha256:configB', 5.days.ago)
    stub_digest_config('sha256:configC', 1.month.ago)
    stub_digest_config('sha256:configD', nil)
  end

  describe '#execute' do
    subject { service.execute(repository) }

    context 'when no params are specified' do
      let(:params) { {} }

      it 'does not remove anything' do
        expect_any_instance_of(ContainerRegistry::Client).not_to receive(:delete_repository_tag)

        is_expected.to include(status: :success, deleted: [])
      end
    end

    context 'when regex matching everything is specified' do
      let(:params) do
        { 'name_regex' => '.*' }
      end

      it 'does remove B* and C' do
        # The :A cannot be removed as config is shared with :latest
        # The :E cannot be removed as it does not have valid manifest

        expect_delete('sha256:configB').twice
        expect_delete('sha256:configC')
        expect_delete('sha256:configD')

        is_expected.to include(status: :success, deleted: %w(D Bb Ba C))
      end
    end

    context 'when regex matching specific tags is used' do
      let(:params) do
        { 'name_regex' => 'C|D' }
      end

      it 'does remove C and D' do
        expect_delete('sha256:configC')
        expect_delete('sha256:configD')

        is_expected.to include(status: :success, deleted: %w(D C))
      end
    end

    context 'when removing a tagged image that is used by another tag' do
      let(:params) do
        { 'name_regex' => 'Ba' }
      end

      it 'does not remove the tag' do
        # Issue: https://gitlab.com/gitlab-org/gitlab-foss/issues/21405

        is_expected.to include(status: :success, deleted: [])
      end
    end

    context 'when removing keeping only 3' do
      let(:params) do
        { 'name_regex' => '.*',
          'keep_n' => 3 }
      end

      it 'does remove C as it is oldest' do
        expect_delete('sha256:configC')

        is_expected.to include(status: :success, deleted: %w(C))
      end
    end

    context 'when removing older than 1 day' do
      let(:params) do
        { 'name_regex' => '.*',
          'older_than' => '1 day' }
      end

      it 'does remove B* and C as they are older than 1 day' do
        expect_delete('sha256:configB').twice
        expect_delete('sha256:configC')

        is_expected.to include(status: :success, deleted: %w(Bb Ba C))
      end
    end

    context 'when combining all parameters' do
      let(:params) do
        { 'name_regex' => '.*',
          'keep_n' => 1,
          'older_than' => '1 day' }
      end

      it 'does remove B* and C' do
        expect_delete('sha256:configB').twice
        expect_delete('sha256:configC')

        is_expected.to include(status: :success, deleted: %w(Bb Ba C))
      end
    end
  end

  private

  def stub_tag_digest(tag, digest)
    allow_any_instance_of(ContainerRegistry::Client)
      .to receive(:repository_tag_digest)
      .with(repository.path, tag) { digest }

    allow_any_instance_of(ContainerRegistry::Client)
      .to receive(:repository_manifest)
      .with(repository.path, tag) do
      { 'config' => { 'digest' => digest } } if digest
    end
  end

  def stub_digest_config(digest, created_at)
    allow_any_instance_of(ContainerRegistry::Client)
      .to receive(:blob)
      .with(repository.path, digest, nil) do
      { 'created' => created_at.to_datetime.rfc3339 }.to_json if created_at
    end
  end

  def expect_delete(digest)
    expect_any_instance_of(ContainerRegistry::Client)
      .to receive(:delete_repository_tag)
      .with(repository.path, digest) { true }
  end
end
