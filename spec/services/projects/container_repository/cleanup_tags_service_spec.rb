# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ContainerRepository::CleanupTagsService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, :private) }
  let_it_be(:repository) { create(:container_repository, :root, project: project) }

  let(:service) { described_class.new(project, user, params) }

  before do
    project.add_maintainer(user)

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
        expect_any_instance_of(Projects::ContainerRepository::DeleteTagsService)
          .not_to receive(:execute)

        is_expected.to include(status: :success, deleted: [])
      end
    end

    context 'when regex matching everything is specified' do
      shared_examples 'removes all matches' do
        it 'does remove all tags except latest' do
          expect_delete(%w(A Ba Bb C D E))

          is_expected.to include(status: :success, deleted: %w(A Ba Bb C D E))
        end
      end

      let(:params) do
        { 'name_regex_delete' => '.*' }
      end

      it_behaves_like 'removes all matches'

      context 'with deprecated name_regex param' do
        let(:params) do
          { 'name_regex' => '.*' }
        end

        it_behaves_like 'removes all matches'
      end
    end

    context 'with invalid regular expressions' do
      RSpec.shared_examples 'handling an invalid regex' do
        it 'keeps all tags' do
          expect(Projects::ContainerRepository::DeleteTagsService)
            .not_to receive(:new)
          subject
        end

        it 'returns an error' do
          response = subject

          expect(response[:status]).to eq(:error)
          expect(response[:message]).to eq('invalid regex')
        end

        it 'calls error tracking service' do
          expect(Gitlab::ErrorTracking).to receive(:log_exception).and_call_original

          subject
        end
      end

      context 'when name_regex_delete is invalid' do
        let(:params) { { 'name_regex_delete' => '*test*' } }

        it_behaves_like 'handling an invalid regex'
      end

      context 'when name_regex is invalid' do
        let(:params) { { 'name_regex' => '*test*' } }

        it_behaves_like 'handling an invalid regex'
      end

      context 'when name_regex_keep is invalid' do
        let(:params) { { 'name_regex_keep' => '*test*' } }

        it_behaves_like 'handling an invalid regex'
      end
    end

    context 'when delete regex matching specific tags is used' do
      let(:params) do
        { 'name_regex_delete' => 'C|D' }
      end

      it 'does remove C and D' do
        expect_delete(%w(C D))

        is_expected.to include(status: :success, deleted: %w(C D))
      end

      context 'with overriding allow regex' do
        let(:params) do
          { 'name_regex_delete' => 'C|D',
            'name_regex_keep' => 'C' }
        end

        it 'does not remove C' do
          expect_delete(%w(D))

          is_expected.to include(status: :success, deleted: %w(D))
        end
      end

      context 'with name_regex_delete overriding deprecated name_regex' do
        let(:params) do
          { 'name_regex' => 'C|D',
            'name_regex_delete' => 'D' }
        end

        it 'does not remove C' do
          expect_delete(%w(D))

          is_expected.to include(status: :success, deleted: %w(D))
        end
      end
    end

    context 'with allow regex value' do
      let(:params) do
        { 'name_regex_delete' => '.*',
          'name_regex_keep' => 'B.*' }
      end

      it 'does not remove B*' do
        expect_delete(%w(A C D E))

        is_expected.to include(status: :success, deleted: %w(A C D E))
      end
    end

    context 'when keeping only N tags' do
      let(:params) do
        { 'name_regex' => 'A|B.*|C',
          'keep_n' => 1 }
      end

      it 'sorts tags by date' do
        expect_delete(%w(Bb Ba C))

        expect(service).to receive(:order_by_date).and_call_original

        is_expected.to include(status: :success, deleted: %w(Bb Ba C))
      end
    end

    context 'when not keeping N tags' do
      let(:params) do
        { 'name_regex' => 'A|B.*|C' }
      end

      it 'does not sort tags by date' do
        expect_delete(%w(A Ba Bb C))

        expect(service).not_to receive(:order_by_date)

        is_expected.to include(status: :success, deleted: %w(A Ba Bb C))
      end
    end

    context 'when removing keeping only 3' do
      let(:params) do
        { 'name_regex_delete' => '.*',
          'keep_n' => 3 }
      end

      it 'does remove B* and C as they are the oldest' do
        expect_delete(%w(Bb Ba C))

        is_expected.to include(status: :success, deleted: %w(Bb Ba C))
      end
    end

    context 'when removing older than 1 day' do
      let(:params) do
        { 'name_regex_delete' => '.*',
          'older_than' => '1 day' }
      end

      it 'does remove B* and C as they are older than 1 day' do
        expect_delete(%w(Ba Bb C))

        is_expected.to include(status: :success, deleted: %w(Ba Bb C))
      end
    end

    context 'when combining all parameters' do
      let(:params) do
        { 'name_regex_delete' => '.*',
          'keep_n' => 1,
          'older_than' => '1 day' }
      end

      it 'does remove B* and C' do
        expect_delete(%w(Bb Ba C))

        is_expected.to include(status: :success, deleted: %w(Bb Ba C))
      end
    end

    context 'when running a container_expiration_policy' do
      let(:user) { nil }

      context 'with valid container_expiration_policy param' do
        let(:params) do
          { 'name_regex_delete' => '.*',
            'keep_n' => 1,
            'older_than' => '1 day',
            'container_expiration_policy' => true }
        end

        it 'succeeds without a user' do
          expect_delete(%w(Bb Ba C), container_expiration_policy: true)

          is_expected.to include(status: :success, deleted: %w(Bb Ba C))
        end
      end

      context 'without container_expiration_policy param' do
        let(:params) do
          { 'name_regex_delete' => '.*',
            'keep_n' => 1,
            'older_than' => '1 day' }
        end

        it 'fails' do
          is_expected.to include(status: :error, message: 'access denied')
        end
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

  def expect_delete(tags, container_expiration_policy: nil)
    expect(Projects::ContainerRepository::DeleteTagsService)
      .to receive(:new)
      .with(repository.project, user, tags: tags, container_expiration_policy: container_expiration_policy)
      .and_call_original

    expect_any_instance_of(Projects::ContainerRepository::DeleteTagsService)
      .to receive(:execute)
      .with(repository) { { status: :success, deleted: tags } }
  end
end
