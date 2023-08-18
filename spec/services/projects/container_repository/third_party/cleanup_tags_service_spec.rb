# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ContainerRepository::ThirdParty::CleanupTagsService, :clean_gitlab_redis_cache, feature_category: :container_registry do
  using RSpec::Parameterized::TableSyntax

  include_context 'for a cleanup tags service'

  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, :private) }

  let(:repository) { create(:container_repository, :root, project: project) }
  let(:service) { described_class.new(container_repository: repository, current_user: user, params: params) }
  let(:tags) { %w[latest A Ba Bb C D E] }

  before do
    project.add_maintainer(user) if user

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
  end

  describe '#execute' do
    subject { service.execute }

    it_behaves_like 'when regex matching everything is specified',
      delete_expectations: [%w[A Ba Bb C D E]],
      service_response_extra: {
        before_truncate_size: 6,
        after_truncate_size: 6,
        before_delete_size: 6,
        cached_tags_count: 0
      },
      supports_caching: true

    it_behaves_like 'when regex matching everything is specified and latest is not kept',
      delete_expectations: [%w[A Ba Bb C D E latest]],
      service_response_extra: {
        before_truncate_size: 7,
        after_truncate_size: 7,
        before_delete_size: 7,
        cached_tags_count: 0
      },
      supports_caching: true

    it_behaves_like 'when delete regex matching specific tags is used',
      service_response_extra: {
        before_truncate_size: 2,
        after_truncate_size: 2,
        before_delete_size: 2,
        cached_tags_count: 0
      },
      supports_caching: true

    it_behaves_like 'when delete regex matching specific tags is used with overriding allow regex',
      service_response_extra: {
        before_truncate_size: 1,
        after_truncate_size: 1,
        before_delete_size: 1,
        cached_tags_count: 0
      },
      supports_caching: true

    it_behaves_like 'with allow regex value',
      delete_expectations: [%w[A C D E]],
      service_response_extra: {
        before_truncate_size: 4,
        after_truncate_size: 4,
        before_delete_size: 4,
        cached_tags_count: 0
      },
      supports_caching: true

    it_behaves_like 'when keeping only N tags',
      delete_expectations: [%w[Bb Ba C]],
      service_response_extra: {
        before_truncate_size: 4,
        after_truncate_size: 4,
        before_delete_size: 3,
        cached_tags_count: 0
      },
      supports_caching: true

    it_behaves_like 'when not keeping N tags',
      delete_expectations: [%w[A Ba Bb C]],
      service_response_extra: {
        before_truncate_size: 4,
        after_truncate_size: 4,
        before_delete_size: 4,
        cached_tags_count: 0
      },
      supports_caching: true

    it_behaves_like 'when removing keeping only 3',
      delete_expectations: [%w[Bb Ba C]],
      service_response_extra: {
        before_truncate_size: 6,
        after_truncate_size: 6,
        before_delete_size: 3,
        cached_tags_count: 0
      },
      supports_caching: true

    it_behaves_like 'when removing older than 1 day',
      delete_expectations: [%w[Ba Bb C]],
      service_response_extra: {
        before_truncate_size: 6,
        after_truncate_size: 6,
        before_delete_size: 3,
        cached_tags_count: 0
      },
      supports_caching: true

    it_behaves_like 'when combining all parameters',
      delete_expectations: [%w[Bb Ba C]],
      service_response_extra: {
        before_truncate_size: 6,
        after_truncate_size: 6,
        before_delete_size: 3,
        cached_tags_count: 0
      },
      supports_caching: true

    it_behaves_like 'when running a container_expiration_policy',
      delete_expectations: [%w[Bb Ba C]],
      service_response_extra: {
        before_truncate_size: 6,
        after_truncate_size: 6,
        before_delete_size: 3,
        cached_tags_count: 0
      },
      supports_caching: true

    context 'when running a container_expiration_policy with caching' do
      let(:user) { nil }
      let(:params) do
        {
          'name_regex_delete' => '.*',
          'keep_n' => 1,
          'older_than' => '1 day',
          'container_expiration_policy' => true
        }
      end

      it 'expects caching to be used' do
        expect_delete(%w[Bb Ba C], container_expiration_policy: true)
        expect_caching

        subject
      end

      context 'when setting set to false' do
        before do
          stub_application_setting(container_registry_expiration_policies_caching: false)
        end

        it 'does not use caching' do
          expect_delete(%w[Bb Ba C], container_expiration_policy: true)
          expect_no_caching

          subject
        end
      end
    end

    context 'when truncating the tags list' do
      let(:params) do
        {
          'name_regex_delete' => '.*',
          'keep_n' => 1
        }
      end

      shared_examples 'returning the response' do
        |status:, original_size:, before_truncate_size:, after_truncate_size:, before_delete_size:|
        it 'returns the response' do
          expect_no_caching

          result = subject

          service_response = expected_service_response(
            status: status,
            original_size: original_size,
            deleted: nil
          ).merge(
            before_truncate_size: before_truncate_size,
            after_truncate_size: after_truncate_size,
            before_delete_size: before_delete_size,
            cached_tags_count: 0
          )

          expect(result).to eq(service_response)
        end
      end

      where(:max_list_size, :delete_tags_service_status, :expected_status, :expected_truncated) do
        10 | :success | :success | false
        10 | :error   | :error   | false
        3  | :success | :error   | true
        3  | :error   | :error   | true
        0  | :success | :success | false
        0  | :error   | :error   | false
      end

      with_them do
        before do
          stub_application_setting(container_registry_cleanup_tags_service_max_list_size: max_list_size)
          allow_next_instance_of(Projects::ContainerRepository::DeleteTagsService) do |service|
            allow(service).to receive(:execute).and_return(status: delete_tags_service_status)
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
          # one tag is filtered out with older_than filter
          before_delete_size: params[:expected_truncated] ? params[:max_list_size] : original_size - keep_n - 1
        )
      end
    end

    context 'with caching', :freeze_time do
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
        expect_delete(%w[Bb Ba C], container_expiration_policy: true)
        # We froze time so we need to set the created_at stubs again
        stub_digest_config('sha256:configA', 1.hour.ago)
        stub_digest_config('sha256:configB', 5.days.ago)
        stub_digest_config('sha256:configC', 1.month.ago)
      end

      it 'caches the created_at values' do
        expect_mget(tags_and_created_ats.keys)
        expect_set(cacheable_tags)

        expect(subject).to include(cached_tags_count: 0)
      end

      context 'with cached values' do
        before do
          ::Gitlab::Redis::Cache.with do |redis|
            redis.set(cache_key('C'), rfc3339(1.month.ago))
          end
        end

        it 'uses them' do
          expect_mget(tags_and_created_ats.keys)

          # because C is already in cache, it should not be cached again
          expect_set(cacheable_tags.except('C'))

          # We will ping the container registry for all tags *except* for C because it's cached
          expect(ContainerRegistry::Blob)
            .to receive(:new).with(repository, { "digest" => "sha256:configA" }).and_call_original
          expect(ContainerRegistry::Blob)
            .to receive(:new).with(repository, { "digest" => "sha256:configB" }).twice.and_call_original
          expect(ContainerRegistry::Blob).not_to receive(:new).with(repository, { "digest" => "sha256:configC" })
          expect(ContainerRegistry::Blob)
            .to receive(:new).with(repository, { "digest" => "sha256:configD" }).and_call_original

          expect(subject).to include(cached_tags_count: 1)
        end
      end

      def expect_mget(keys)
        Gitlab::Redis::Cache.with do |redis|
          parameters = keys.map { |k| cache_key(k) }
          expect(redis).to receive(:mget).with(parameters).and_call_original
        end
      end

      def expect_set(tags)
        selected_tags = tags.map do |tag_name, created_at|
          ex = 1.day.seconds - (Time.zone.now - created_at).seconds
          [tag_name, created_at, ex.to_i] if ex.positive?
        end.compact

        return if selected_tags.count.zero?

        Gitlab::Redis::Cache.with do |redis|
          expect(redis).to receive(:pipelined).and_call_original

          expect_next_instance_of(Redis::PipelinedConnection) do |pipeline|
            selected_tags.each do |tag_name, created_at, ex|
              expect(pipeline).to receive(:set).with(cache_key(tag_name), rfc3339(created_at), ex: ex).and_call_original
            end
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
    allow(repository.client)
      .to receive(:repository_tag_digest)
      .with(repository.path, tag) { digest }

    allow(repository.client)
      .to receive(:repository_manifest)
      .with(repository.path, tag) do
      { 'config' => { 'digest' => digest } } if digest
    end
  end

  def stub_digest_config(digest, created_at)
    allow(repository.client)
      .to receive(:blob)
      .with(repository.path, digest, nil) do
      { 'created' => created_at.to_datetime.rfc3339 }.to_json if created_at
    end
  end

  def expect_caching
    ::Gitlab::Redis::Cache.with do |redis|
      expect(redis).to receive(:mget).and_call_original
      expect(redis).to receive(:pipelined).and_call_original

      expect_next_instance_of(Redis::PipelinedConnection) do |pipeline|
        expect(pipeline).to receive(:set).and_call_original
      end
    end
  end
end
