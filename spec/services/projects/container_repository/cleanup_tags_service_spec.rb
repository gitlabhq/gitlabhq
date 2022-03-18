# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ContainerRepository::CleanupTagsService, :clean_gitlab_redis_cache do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, :private) }

  let(:repository) { create(:container_repository, :root, project: project) }
  let(:service) { described_class.new(repository, user, params) }
  let(:tags) { %w[latest A Ba Bb C D E] }

  before do
    project.add_maintainer(user)

    stub_container_registry_config(enabled: true)

    stub_container_registry_tags(
      repository: repository.path,
      tags: tags
    )

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

    stub_feature_flags(container_registry_expiration_policies_throttling: false)
  end

  describe '#execute' do
    subject { service.execute }

    context 'when no params are specified' do
      let(:params) { {} }

      it 'does not remove anything' do
        expect_any_instance_of(Projects::ContainerRepository::DeleteTagsService)
          .not_to receive(:execute)
        expect_no_caching

        is_expected.to eq(expected_service_response(before_truncate_size: 0, after_truncate_size: 0, before_delete_size: 0))
      end
    end

    context 'when regex matching everything is specified' do
      shared_examples 'removes all matches' do
        it 'does remove all tags except latest' do
          expect_no_caching

          expect_delete(%w(A Ba Bb C D E))

          is_expected.to eq(expected_service_response(deleted: %w(A Ba Bb C D E)))
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
      shared_examples 'handling an invalid regex' do
        it 'keeps all tags' do
          expect_no_caching

          expect(Projects::ContainerRepository::DeleteTagsService)
            .not_to receive(:new)

          subject
        end

        it { is_expected.to eq(status: :error, message: 'invalid regex') }

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

        expect_no_caching

        is_expected.to eq(expected_service_response(deleted: %w(C D), before_truncate_size: 2, after_truncate_size: 2, before_delete_size: 2))
      end

      context 'with overriding allow regex' do
        let(:params) do
          { 'name_regex_delete' => 'C|D',
            'name_regex_keep' => 'C' }
        end

        it 'does not remove C' do
          expect_delete(%w(D))

          expect_no_caching

          is_expected.to eq(expected_service_response(deleted: %w(D), before_truncate_size: 1, after_truncate_size: 1, before_delete_size: 1))
        end
      end

      context 'with name_regex_delete overriding deprecated name_regex' do
        let(:params) do
          { 'name_regex' => 'C|D',
            'name_regex_delete' => 'D' }
        end

        it 'does not remove C' do
          expect_delete(%w(D))

          expect_no_caching

          is_expected.to eq(expected_service_response(deleted: %w(D), before_truncate_size: 1, after_truncate_size: 1, before_delete_size: 1))
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

        expect_no_caching

        is_expected.to eq(expected_service_response(deleted: %w(A C D E), before_truncate_size: 4, after_truncate_size: 4, before_delete_size: 4))
      end
    end

    context 'when keeping only N tags' do
      let(:params) do
        { 'name_regex' => 'A|B.*|C',
          'keep_n' => 1 }
      end

      it 'sorts tags by date' do
        expect_delete(%w(Bb Ba C))

        expect_no_caching

        expect(service).to receive(:order_by_date).and_call_original

        is_expected.to eq(expected_service_response(deleted: %w(Bb Ba C), before_truncate_size: 4, after_truncate_size: 4, before_delete_size: 3))
      end
    end

    context 'when not keeping N tags' do
      let(:params) do
        { 'name_regex' => 'A|B.*|C' }
      end

      it 'does not sort tags by date' do
        expect_delete(%w(A Ba Bb C))

        expect_no_caching

        expect(service).not_to receive(:order_by_date)

        is_expected.to eq(expected_service_response(deleted: %w(A Ba Bb C), before_truncate_size: 4, after_truncate_size: 4, before_delete_size: 4))
      end
    end

    context 'when removing keeping only 3' do
      let(:params) do
        { 'name_regex_delete' => '.*',
          'keep_n' => 3 }
      end

      it 'does remove B* and C as they are the oldest' do
        expect_delete(%w(Bb Ba C))

        expect_no_caching

        is_expected.to eq(expected_service_response(deleted: %w(Bb Ba C), before_delete_size: 3))
      end
    end

    context 'when removing older than 1 day' do
      let(:params) do
        { 'name_regex_delete' => '.*',
          'older_than' => '1 day' }
      end

      it 'does remove B* and C as they are older than 1 day' do
        expect_delete(%w(Ba Bb C))

        expect_no_caching

        is_expected.to eq(expected_service_response(deleted: %w(Ba Bb C), before_delete_size: 3))
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

        expect_no_caching

        is_expected.to eq(expected_service_response(deleted: %w(Bb Ba C), before_delete_size: 3))
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

        before do
          expect_delete(%w(Bb Ba C), container_expiration_policy: true)
        end

        it { is_expected.to eq(expected_service_response(deleted: %w(Bb Ba C), before_delete_size: 3)) }

        context 'caching' do
          it 'expects caching to be used' do
            expect_caching

            subject
          end

          context 'when setting set to false' do
            before do
              stub_application_setting(container_registry_expiration_policies_caching: false)
            end

            it 'does not use caching' do
              expect_no_caching

              subject
            end
          end
        end
      end

      context 'without container_expiration_policy param' do
        let(:params) do
          { 'name_regex_delete' => '.*',
            'keep_n' => 1,
            'older_than' => '1 day' }
        end

        it 'fails' do
          is_expected.to eq(status: :error, message: 'access denied')
        end
      end
    end

    context 'truncating the tags list' do
      let(:params) do
        {
          'name_regex_delete' => '.*',
          'keep_n' => 1
        }
      end

      shared_examples 'returning the response' do |status:, original_size:, before_truncate_size:, after_truncate_size:, before_delete_size:|
        it 'returns the response' do
          expect_no_caching

          result = subject

          service_response = expected_service_response(
            status: status,
            original_size: original_size,
            before_truncate_size: before_truncate_size,
            after_truncate_size: after_truncate_size,
            before_delete_size: before_delete_size,
            deleted: nil
          )

          expect(result).to eq(service_response)
        end
      end

      where(:feature_flag_enabled, :max_list_size, :delete_tags_service_status, :expected_status, :expected_truncated) do
        false | 10 | :success | :success | false
        false | 10 | :error   | :error   | false
        false | 3  | :success | :success | false
        false | 3  | :error   | :error   | false
        false | 0  | :success | :success | false
        false | 0  | :error   | :error   | false
        true  | 10 | :success | :success | false
        true  | 10 | :error   | :error   | false
        true  | 3  | :success | :error   | true
        true  | 3  | :error   | :error   | true
        true  | 0  | :success | :success | false
        true  | 0  | :error   | :error   | false
      end

      with_them do
        before do
          stub_feature_flags(container_registry_expiration_policies_throttling: feature_flag_enabled)
          stub_application_setting(container_registry_cleanup_tags_service_max_list_size: max_list_size)
          allow_next_instance_of(Projects::ContainerRepository::DeleteTagsService) do |service|
            expect(service).to receive(:execute).and_return(status: delete_tags_service_status)
          end
        end

        original_size = 7
        keep_n = 1

        it_behaves_like(
          'returning the response',
          status: params[:expected_status],
          original_size: original_size,
          before_truncate_size: original_size - keep_n,
          after_truncate_size: params[:expected_truncated] ? params[:max_list_size] + keep_n : original_size - keep_n,
          before_delete_size: params[:expected_truncated] ? params[:max_list_size] : original_size - keep_n - 1 # one tag is filtered out with older_than filter
        )
      end
    end

    context 'caching', :freeze_time do
      let(:params) do
        {
          'name_regex_delete' => '.*',
          'keep_n' => 1,
          'older_than' => '1 day',
          'container_expiration_policy' => true
        }
      end

      let(:tags_and_created_ats) do
        {
          'A' => 1.hour.ago,
          'Ba' => 5.days.ago,
          'Bb' => 5.days.ago,
          'C' => 1.month.ago,
          'D' => nil,
          'E' => nil
        }
      end

      let(:cacheable_tags) { tags_and_created_ats.reject { |_, value| value.nil? } }

      before do
        expect_delete(%w(Bb Ba C), container_expiration_policy: true)
        # We froze time so we need to set the created_at stubs again
        stub_digest_config('sha256:configA', 1.hour.ago)
        stub_digest_config('sha256:configB', 5.days.ago)
        stub_digest_config('sha256:configC', 1.month.ago)
      end

      it 'caches the created_at values' do
        ::Gitlab::Redis::Cache.with do |redis|
          expect_mget(redis, tags_and_created_ats.keys)

          expect_set(redis, cacheable_tags)
        end

        expect(subject).to include(cached_tags_count: 0)
      end

      context 'with cached values' do
        before do
          ::Gitlab::Redis::Cache.with do |redis|
            redis.set(cache_key('C'), rfc3339(1.month.ago))
          end
        end

        it 'uses them' do
          ::Gitlab::Redis::Cache.with do |redis|
            expect_mget(redis, tags_and_created_ats.keys)

            # because C is already in cache, it should not be cached again
            expect_set(redis, cacheable_tags.except('C'))
          end

          # We will ping the container registry for all tags *except* for C because it's cached
          expect(ContainerRegistry::Blob).to receive(:new).with(repository, "digest" => "sha256:configA").and_call_original
          expect(ContainerRegistry::Blob).to receive(:new).with(repository, "digest" => "sha256:configB").twice.and_call_original
          expect(ContainerRegistry::Blob).not_to receive(:new).with(repository, "digest" => "sha256:configC")
          expect(ContainerRegistry::Blob).to receive(:new).with(repository, "digest" => "sha256:configD").and_call_original

          expect(subject).to include(cached_tags_count: 1)
        end
      end

      def expect_mget(redis, keys)
        expect(redis).to receive(:mget).with(keys.map(&method(:cache_key))).and_call_original
      end

      def expect_set(redis, tags)
        tags.each do |tag_name, created_at|
          ex = 1.day.seconds - (Time.zone.now - created_at).seconds
          if ex > 0
            expect(redis).to receive(:set).with(cache_key(tag_name), rfc3339(created_at), ex: ex.to_i)
          end
        end
      end

      def cache_key(tag_name)
        "container_repository:{#{repository.id}}:tag:#{tag_name}:created_at"
      end

      def rfc3339(date_time)
        # DateTime rfc3339 is different ActiveSupport::TimeWithZone rfc3339
        # The caching will use DateTime rfc3339
        DateTime.rfc3339(date_time.rfc3339).rfc3339
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

  # all those -1 because the default tags on L13 have a "latest" that will be filtered out
  def expected_service_response(status: :success, deleted: [], original_size: tags.size, before_truncate_size: tags.size - 1, after_truncate_size: tags.size - 1, before_delete_size: tags.size - 1)
    {
      status: status,
      deleted: deleted,
      original_size: original_size,
      before_truncate_size: before_truncate_size,
      after_truncate_size: after_truncate_size,
      before_delete_size: before_delete_size,
      cached_tags_count: 0
    }.compact.merge(deleted_size: deleted&.size)
  end

  def expect_no_caching
    expect(::Gitlab::Redis::Cache).not_to receive(:with)
  end

  def expect_caching
    ::Gitlab::Redis::Cache.with do |redis|
      expect(redis).to receive(:mget).and_call_original
      expect(redis).to receive(:set).and_call_original
    end
  end
end
