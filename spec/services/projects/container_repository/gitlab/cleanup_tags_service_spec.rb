# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ContainerRepository::Gitlab::CleanupTagsService, feature_category: :container_registry do
  using RSpec::Parameterized::TableSyntax

  include_context 'for a cleanup tags service'

  let_it_be(:user) { create(:user) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, :private) }

  let(:repository) { create(:container_repository, :root, project: project) }
  let(:service) { described_class.new(container_repository: repository, current_user: user, params: params) }
  let(:tags) { %w[latest A Ba Bb C D E] }

  before do
    project.add_maintainer(user) if user

    stub_container_registry_config(enabled: true)

    stub_const("#{described_class}::TAGS_PAGE_SIZE", tags_page_size)

    allow(repository.gitlab_api_client).to receive(:supports_gitlab_api?).and_return(true)

    one_hour_ago = 1.hour.ago
    five_days_ago = 5.days.ago
    six_days_ago = 6.days.ago
    one_month_ago = 1.month.ago

    stub_tags(
      {
        'latest' => one_hour_ago,
        'A' => one_hour_ago,
        'Ba' => five_days_ago,
        'Bb' => six_days_ago,
        'C' => one_month_ago,
        'D' => nil,
        'E' => nil
      }
    )
  end

  describe '#execute' do
    subject { service.execute }

    context 'with several tags pages' do
      let(:tags_page_size) { 2 }

      it_behaves_like 'when regex matching everything is specified',
        delete_expectations: [%w[A], %w[Ba Bb], %w[C D], %w[E]]

      it_behaves_like 'when regex matching everything is specified and latest is not kept',
        delete_expectations: [%w[latest A], %w[Ba Bb], %w[C D], %w[E]]

      it_behaves_like 'when delete regex matching specific tags is used'

      it_behaves_like 'when delete regex matching specific tags is used with overriding allow regex'

      it_behaves_like 'with allow regex value',
        delete_expectations: [%w[A], %w[C D], %w[E]]

      it_behaves_like 'when keeping only N tags',
        delete_expectations: [%w[Bb]]

      it_behaves_like 'when not keeping N tags',
        delete_expectations: [%w[A], %w[Ba Bb], %w[C]]

      context 'when removing keeping only 3' do
        let(:params) do
          {
            'name_regex_delete' => '.*',
            'keep_n' => 3
          }
        end

        it_behaves_like 'not removing anything'
      end

      it_behaves_like 'when removing older than 1 day',
        delete_expectations: [%w[Ba Bb], %w[C]]

      it_behaves_like 'when combining all parameters',
        delete_expectations: [%w[Bb], %w[C]]

      it_behaves_like 'when running a container_expiration_policy',
        delete_expectations: [%w[Bb], %w[C]]

      context 'with a timeout' do
        let(:params) do
          { 'name_regex_delete' => '.*' }
        end

        it 'removes the first few pages' do
          expect(service).to receive(:timeout?).and_return(false, true)

          expect_delete(%w[A])
          expect_delete(%w[Ba Bb])

          response = expected_service_response(status: :error, deleted: %w[A Ba Bb], original_size: 4)

          is_expected.to eq(response)
        end

        context 'when disable_timeout is set to true' do
          let(:params) do
            { 'name_regex_delete' => '.*', 'disable_timeout' => true }
          end

          it 'does not check if it timed out' do
            expect(service).not_to receive(:timeout?)
          end

          it_behaves_like 'when regex matching everything is specified',
            delete_expectations: [%w[A], %w[Ba Bb], %w[C D], %w[E]]
        end
      end
    end

    context 'with a single tags page' do
      let(:tags_page_size) { 1000 }

      it_behaves_like 'when regex matching everything is specified',
        delete_expectations: [%w[A Ba Bb C D E]]

      it_behaves_like 'when delete regex matching specific tags is used'

      it_behaves_like 'when delete regex matching specific tags is used with overriding allow regex'

      it_behaves_like 'with allow regex value',
        delete_expectations: [%w[A C D E]]

      it_behaves_like 'when keeping only N tags',
        delete_expectations: [%w[Ba Bb C]]

      it_behaves_like 'when not keeping N tags',
        delete_expectations: [%w[A Ba Bb C]]

      it_behaves_like 'when removing keeping only 3',
        delete_expectations: [%w[Ba Bb C]]

      it_behaves_like 'when removing older than 1 day',
        delete_expectations: [%w[Ba Bb C]]

      it_behaves_like 'when combining all parameters',
        delete_expectations: [%w[Ba Bb C]]

      it_behaves_like 'when running a container_expiration_policy',
        delete_expectations: [%w[Ba Bb C]]
    end

    context 'with no tags page' do
      let(:tags_page_size) { 1000 }
      let(:deleted) { [] }
      let(:params) { {} }

      before do
        allow(repository.gitlab_api_client)
          .to receive(:tags)
          .and_return({})
      end

      it { is_expected.to eq(expected_service_response(status: :success, deleted: [], original_size: 0)) }
    end
  end

  private

  def stub_tags(tags)
    chunked = tags_page_size < tags.size
    previous_last = nil
    max_chunk_index = tags.size / tags_page_size

    tags.keys.in_groups_of(tags_page_size, false).each_with_index do |chunked_tag_names, index|
      last = index == max_chunk_index
      pagination_needed = chunked && !last

      response = {
        pagination: pagination_needed ? pagination_with(last: chunked_tag_names.last) : {},
        response_body: chunked_tag_names.map do |name|
          tag_raw_response(name, tags[name])
        end
      }

      allow(repository.gitlab_api_client)
        .to receive(:tags)
        .with(repository.path, page_size: described_class::TAGS_PAGE_SIZE, last: previous_last)
        .and_return(response)
      previous_last = chunked_tag_names.last
    end
  end

  def pagination_with(last:)
    {
      next: {
        uri: URI("http://test.org?last=#{last}")
      }
    }
  end

  def tag_raw_response(name, timestamp)
    timestamp_field = name.start_with?('B') ? 'updated_at' : 'created_at'
    {
      'name' => name,
      'digest' => 'sha256:1234567890',
      'media_type' => 'application/vnd.oci.image.manifest.v1+json',
      timestamp_field => timestamp&.iso8601
    }
  end
end
