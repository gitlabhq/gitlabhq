# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRepository, :aggregate_failures, feature_category: :container_registry do
  include_context 'container registry client stubs'

  using RSpec::Parameterized::TableSyntax

  let(:group) { create(:group, name: 'group') }
  let(:project) { create(:project, path: 'test', group: group) }

  let(:repository) do
    create(:container_repository, name: 'my_image', project: project)
  end

  before do
    stub_container_registry_config(
      enabled: true, api_url: 'http://registry.gitlab', host_port: 'registry.gitlab'
    )

    stub_request(:get, "http://registry.gitlab/v2/group/test/my_image/tags/list?n=#{::ContainerRegistry::Client::DEFAULT_TAGS_PAGE_SIZE}")
      .with(headers: { 'Accept' => ContainerRegistry::Client::ACCEPTED_TYPES.join(', ') })
      .to_return(
        status: 200,
        body: Gitlab::Json.dump(tags: ['test_tag']),
        headers: { 'Content-Type' => 'application/json' })
  end

  it_behaves_like 'having unique enum values'

  describe 'associations' do
    it 'belongs to the project' do
      expect(repository).to belong_to(:project)
    end
  end

  context 'when triggering registry API requests' do
    let(:repository_state) { nil }
    let(:repository) { create(:container_repository, repository_state) }

    shared_examples 'a state machine configured with use_transactions: false' do
      it 'executes the registry API request outside of a transaction', :delete do
        expect(repository).to receive(:save).and_call_original do
          expect(ApplicationRecord.connection.transaction_open?).to be true
        end

        subject
      end
    end
  end

  describe '#last_published_at' do
    subject { repository.last_published_at }

    context 'when the GitLab API is supported' do
      before do
        stub_container_registry_gitlab_api_support(supported: true)
        expect(repository.gitlab_api_client).to receive(:repository_details).with(repository.path, sizing: :self).and_return(response)
      end

      context 'with a size_bytes field' do
        let(:timestamp_string) { '2024-04-30T06:07:36.225Z' }
        let(:response) { { 'last_published_at' => timestamp_string } }

        it { is_expected.to eq(DateTime.iso8601(timestamp_string)) }
      end

      context 'without a last_published_at field' do
        let(:response) { { 'foo' => 'bar' } }

        it { is_expected.to eq(nil) }
      end

      context 'with an invalid value for the last_published_at field' do
        let(:response) { { 'last_published_at' => 'foobar' } }

        it { is_expected.to eq(nil) }
      end
    end

    context 'when the GitLab API is not supported' do
      before do
        stub_container_registry_gitlab_api_support(supported: false)
        expect(repository.gitlab_api_client).not_to receive(:repository_details)
      end

      it { is_expected.to eq(nil) }
    end
  end

  describe '#tag' do
    shared_examples 'returning an instantiated tag' do
      it 'returns an instantiated tag' do
        allow(ContainerRegistry::Tag).to receive(:new).and_call_original
        tag = repository.tag('test')

        expect(tag).to be_a ContainerRegistry::Tag
        expect(tag).to have_attributes(
          repository: repository,
          name: 'test'
        )

        expect(ContainerRegistry::Tag).to have_received(:new).with(repository, 'test')
      end
    end

    context 'when Gitlab API is supported' do
      before do
        allow(repository.gitlab_api_client).to receive(:supports_gitlab_api?).and_return(true)
      end

      shared_examples 'returning an instantiated tag from the API response' do
        let_it_be(:response_body) do
          {
            pagination: {},
            response_body: ::Gitlab::Json.parse(tags_response.to_json)
          }
        end

        before do
          allow(repository.gitlab_api_client).to receive(:tags).and_return(response_body)
          allow(ContainerRegistry::Tag).to receive(:new).and_call_original
        end

        it 'returns an instantiated tag from the response' do
          tag = repository.tag('test')

          expect(ContainerRegistry::Tag).to have_received(:new).with(repository, 'test', from_api: true)

          expect(tag).to be_a ContainerRegistry::Tag
          expect(tag).to have_attributes(
            repository: repository,
            name: 'test',
            digest: tags_response[0][:digest],
            total_size: tags_response[0][:size_bytes]
          )
        end
      end

      context 'when the Gitlab API returns a tag' do
        let_it_be(:tags_response) do
          [
            {
              name: 'test',
              digest: 'sha256:6c3c647c6eebdaab7c610cf7d66709b3',
              size_bytes: 1234567892
            }
          ]
        end

        it_behaves_like 'returning an instantiated tag from the API response'
      end

      context 'when the Gitlab API returns multiple tags' do
        let_it_be(:tags_response) do
          [
            {
              name: 'a-test',
              digest: 'sha256:6c3c647c6eebdaab7c610cf7d66709b3',
              size_bytes: 1234567892
            },
            {
              name: 'test',
              digest: 'sha256:6c3c647c6eebdaab7c610cf7d66709b3',
              size_bytes: 1234567892
            },

            {
              name: 'test-a',
              digest: 'sha256:6c3c647c6eebdaab7c610cf7d66709b3',
              size_bytes: 1234567892
            }
          ]
        end

        it_behaves_like 'returning an instantiated tag from the API response'
      end

      context 'when the Gitlab API does not return a tag' do
        before do
          allow(repository.gitlab_api_client).to receive(:tags).and_return({ pagination: {}, response_body: {} })
        end

        it 'returns nil' do
          expect(repository.tag('test')).to be_nil
        end
      end
    end

    context 'when the Gitlab API is not supported' do
      before do
        stub_container_registry_gitlab_api_support(supported: false)
      end

      it_behaves_like 'returning an instantiated tag'
    end
  end

  describe '#path' do
    context 'when project path does not contain uppercase letters' do
      it 'returns a full path to the repository' do
        expect(repository.path).to eq('group/test/my_image')
      end
    end

    context 'when path contains uppercase letters' do
      let(:project) { create(:project, :repository, path: 'MY_PROJECT', group: group) }

      it 'returns a full path without capital letters' do
        expect(repository.path).to eq('group/my_project/my_image')
      end
    end
  end

  describe '#manifest' do
    it 'returns non-empty manifest' do
      expect(repository.manifest).not_to be_nil
    end
  end

  describe '#image_manifest' do
    let(:ref) { 'latest' }
    let(:manifest_content) { '{"data":"example"}' }

    it 'returns an image manifest from the registry' do
      allow_next_instance_of(ContainerRegistry::Client) do |client|
        allow(client).to receive(:repository_manifest)
          .with(repository.path, ref)
          .and_return(manifest_content)
      end

      expect(repository.image_manifest(ref)).to eq(manifest_content)
    end
  end

  describe '#valid?' do
    it 'is a valid repository' do
      expect(repository).to be_valid
    end
  end

  describe '#tags' do
    shared_examples 'returning the non-empty tags list' do
      it 'returns non-empty tags list' do
        expect(repository.tags).not_to be_empty
      end
    end

    context 'when Gitlab API is supported' do
      before do
        stub_container_registry_gitlab_api_support(supported: true)
      end

      context 'when the Gitlab API returns tags' do
        include_context 'with the container registry GitLab API returning tags'

        before do
          allow(repository.gitlab_api_client).to receive(:tags).and_return(response_body)
          allow(repository).to receive(:each_tags_page).and_call_original
        end

        it 'returns an instantiated tag from the response' do
          tags = repository.tags

          expect(repository).to have_received(:each_tags_page)
          expect(tags).to match_array([
            have_attributes(
              repository: repository,
              name: tags_response[0][:name],
              digest: tags_response[0][:digest],
              total_size: tags_response[0][:size_bytes]
            ),
            have_attributes(
              repository: repository,
              name: tags_response[1][:name],
              digest: tags_response[1][:digest],
              total_size: tags_response[1][:size_bytes]
            )
          ])
        end
      end

      context 'when the Gitlab API does not return any tags' do
        before do
          allow(repository.gitlab_api_client).to receive(:tags).and_return({ pagination: {}, response_body: {} })
        end

        it 'returns an empty array' do
          expect(repository.tags).to be_empty
        end
      end
    end

    context 'when the Gitlab API is not supported' do
      before do
        stub_container_registry_gitlab_api_support(supported: false)
      end

      it_behaves_like 'returning the non-empty tags list'
    end
  end

  describe '#each_tags_page' do
    let(:page_size) { 100 }

    before do
      allow(repository.gitlab_api_client).to receive(:supports_gitlab_api?).and_return(true)
    end

    shared_examples 'iterating through a page' do |expected_tags: true|
      it 'iterates through one page' do
        expect(repository.gitlab_api_client).to receive(:tags)
                                                  .with(repository.path, page_size: page_size, last: nil)
                                                  .and_return(client_response)
        expect { |b| repository.each_tags_page(page_size: page_size, &b) }
          .to yield_with_args(expected_tags ? expected_tags_from(client_response_tags) : [])
      end
    end

    context 'with an empty page' do
      let(:client_response) { { pagination: {}, response_body: [] } }

      it_behaves_like 'iterating through a page', expected_tags: false
    end

    context 'with one page' do
      let(:client_response) { { pagination: {}, response_body: client_response_tags } }
      let(:client_response_tags) do
        [
          {
            'name' => '0.1.0',
            'created_at' => '2022-06-07T12:10:12.412+00:00'
          },
          {
            'name' => 'latest',
            'created_at' => '2022-06-07T12:11:13.633+00:00'
          }
        ]
      end

      context 'with a nil created_at' do
        let(:client_response_tags) { ['name' => '0.1.0', 'created_at' => nil] }

        it_behaves_like 'iterating through a page'
      end

      context 'with an invalid created_at' do
        let(:client_response_tags) { ['name' => '0.1.0', 'created_at' => 'not_a_timestamp'] }

        it_behaves_like 'iterating through a page'
      end
    end

    context 'with two pages' do
      let(:client_response1) { { pagination: { next: { uri: URI('http://localhost/next?last=latest') } }, response_body: client_response_tags1 } }
      let(:client_response_tags1) do
        [
          {
            'name' => '0.1.0',
            'created_at' => '2022-06-07T12:10:12.412+00:00'
          },
          {
            'name' => 'latest',
            'created_at' => '2022-06-07T12:11:13.633+00:00'
          }
        ]
      end

      let(:client_response2) { { pagination: {}, response_body: client_response_tags2 } }
      let(:client_response_tags2) do
        [
          {
            'name' => '1.2.3',
            'created_at' => '2022-06-10T12:10:15.412+00:00'
          },
          {
            'name' => '2.3.4',
            'created_at' => '2022-06-11T12:11:17.633+00:00'
          }
        ]
      end

      it 'iterates through two pages' do
        expect(repository.gitlab_api_client).to receive(:tags)
                                                  .with(repository.path, page_size: page_size, last: nil)
                                                  .and_return(client_response1)
        expect(repository.gitlab_api_client).to receive(:tags)
                                                  .with(repository.path, page_size: page_size, last: 'latest')
                                                  .and_return(client_response2)
        expect { |b| repository.each_tags_page(page_size: page_size, &b) }
          .to yield_successive_args(expected_tags_from(client_response_tags1), expected_tags_from(client_response_tags2))
      end
    end

    context 'when max pages is reached' do
      before do
        stub_const('ContainerRepository::MAX_TAGS_PAGES', 0)
      end

      it 'raises an error' do
        expect { repository.each_tags_page(page_size: page_size) {} }
          .to raise_error(StandardError, 'too many pages requested')
      end
    end

    context 'without a block set' do
      it 'raises an Argument error' do
        expect { repository.each_tags_page(page_size: page_size) }.to raise_error(ArgumentError, 'block not given')
      end
    end

    context 'without a page size set' do
      let(:client_response) { { pagination: {}, response_body: [] } }

      it 'uses a default size' do
        expect(repository.gitlab_api_client).to receive(:tags)
                                                  .with(repository.path, page_size: 100, last: nil)
                                                  .and_return(client_response)
        expect { |b| repository.each_tags_page(&b) }.to yield_with_args([])
      end
    end

    context 'with an empty client response' do
      let(:client_response) { {} }

      it 'breaks the loop' do
        expect(repository.gitlab_api_client).to receive(:tags)
                                                  .with(repository.path, page_size: page_size, last: nil)
                                                  .and_return(client_response)
        expect { |b| repository.each_tags_page(page_size: page_size, &b) }.not_to yield_control
      end
    end

    context 'with a nil page' do
      let(:client_response) { { pagination: {}, response_body: nil } }

      it_behaves_like 'iterating through a page', expected_tags: false
    end

    context 'when the Gitlab API is is not supported' do
      before do
        allow(repository.gitlab_api_client).to receive(:supports_gitlab_api?).and_return(false)
      end

      it 'raises an Argument error' do
        expect { repository.each_tags_page }.to raise_error(ArgumentError, _('GitLab container registry API not supported'))
      end
    end

    def expected_tags_from(client_tags)
      client_tags.map do |tag|
        created_at =
          begin
            DateTime.iso8601(tag['created_at'])
          rescue ArgumentError
            nil
          end
        an_object_having_attributes(name: tag['name'], created_at: created_at)
      end
    end
  end

  describe '#tags_page' do
    let_it_be(:page_size) { 100 }
    let_it_be(:before) { 'before' }
    let_it_be(:last) { 'last' }
    let_it_be(:sort) { '-name' }
    let_it_be(:name) { 'repo' }
    let_it_be(:referrers) { true }
    let_it_be(:referrer_type) { 'application/example' }

    subject do
      repository.tags_page(before: before, last: last, sort: sort, name: name, page_size: page_size,
        referrers: referrers, referrer_type: referrer_type)
    end

    before do
      allow(repository.gitlab_api_client).to receive(:supports_gitlab_api?).and_return(true)
    end

    it 'calls GitlabApiClient#tags and passes parameters' do
      allow(repository.gitlab_api_client).to receive(:tags).and_return({})
      expect(repository.gitlab_api_client).to receive(:tags).with(
        repository.path, page_size: page_size, before: before, last: last, sort: sort, name: name,
        referrers: referrers, referrer_type: referrer_type)

      subject
    end

    context 'with a call to tags' do
      let_it_be(:created_at) { 15.minutes.ago }
      let_it_be(:updated_at) { 10.minutes.ago }
      let_it_be(:published_at) { 5.minutes.ago }

      let_it_be(:tags_response) do
        [
          {
            name: '0.1.0',
            digest: 'sha256:6c3c624b58dbbcd3c0dd82b4c53f04194d1247c6eebdaab7c610cf7d6670',
            config_digest: 'sha256:66b1132a0173910b01ee69583bbf2f7f1e4462c99efbe1b9ab5bf',
            media_type: 'application/vnd.oci.image.manifest.v1+json',
            size_bytes: 1234567890,
            created_at: created_at,
            updated_at: updated_at,
            published_at: published_at,
            referrers: [
              {
                artifactType: 'application/vnd.example+type',
                digest: 'sha256:57d3be92c2f857566ecc7f9306a80021c0a7fa631e0ef5146957235aea859961'
              }
            ]
          },
          {
            name: 'latest',
            digest: 'sha256:6c3c624b58dbbcd3c0dd82b4c53f04191247c6eebdaab7c610cf7d66709b3',
            config_digest: nil,
            media_type: 'application/vnd.oci.image.manifest.v1+json',
            size_bytes: 1234567892,
            created_at: created_at,
            updated_at: updated_at,
            published_at: published_at
          }
        ]
      end

      let_it_be(:response_body) do
        {
          pagination: {
            previous: { uri: URI('/test?before=prev-cursor') },
            next: { uri: URI('/test?last=next-cursor') }
          },
          response_body: ::Gitlab::Json.parse(tags_response.to_json)
        }
      end

      before do
        allow(repository.gitlab_api_client).to receive(:tags).and_return(response_body)
      end

      it 'returns tags and parses the previous and next cursors' do
        return_value = subject

        expect(return_value[:pagination]).to eq(response_body[:pagination])

        return_value[:tags].each_with_index do |tag, index|
          expected_revision = tags_response[index][:config_digest].to_s.split(':')[1].to_s

          expect(tag.is_a?(ContainerRegistry::Tag)).to eq(true)
          expect(tag).to have_attributes(
            repository: repository,
            name: tags_response[index][:name],
            digest: tags_response[index][:digest],
            total_size: tags_response[index][:size_bytes],
            revision: expected_revision,
            short_revision: expected_revision[0..8],
            created_at: DateTime.rfc3339(tags_response[index][:created_at].rfc3339),
            updated_at: DateTime.rfc3339(tags_response[index][:updated_at].rfc3339),
            published_at: DateTime.rfc3339(tags_response[index][:published_at].rfc3339),
            media_type: tags_response[index][:media_type]
          )

          Array(tag.referrers).each_with_index do |ref, ref_index|
            expect(ref.is_a?(ContainerRegistry::Referrer)).to eq(true)
            expect(ref).to have_attributes(
              artifact_type: tags_response[index][:referrers][ref_index][:artifactType],
              digest: tags_response[index][:referrers][ref_index][:digest]
            )
          end
        end
      end
    end

    context 'when the Gitlab API is is not supported' do
      before do
        allow(repository.gitlab_api_client).to receive(:supports_gitlab_api?).and_return(false)
      end

      it 'raises an Argument error' do
        expect { repository.tags_page }.to raise_error(ArgumentError, _('GitLab container registry API not supported'))
      end
    end
  end

  describe '#tags_count' do
    it 'returns the count of tags' do
      expect(repository.tags_count).to eq(1)
    end
  end

  describe '#has_tags?' do
    context 'when there are no tags' do
      before do
        allow(repository).to receive(:tags).and_return([])
      end

      it 'does not have tags' do
        expect(repository).not_to have_tags
      end
    end

    context 'when there are tags' do
      before do
        allow(repository).to receive(:tags).and_return([ContainerRegistry::Tag.new(repository, 'tag1')])
      end

      it 'have tags' do
        expect(repository).to have_tags
      end
    end
  end

  describe '#delete_tags!' do
    let(:repository) do
      create(
        :container_repository,
        name: 'my_image',
        tags: { latest: '123', rc1: '234' },
        project: project
      )
    end

    context 'when there are no tags' do
      before do
        allow(repository).to receive(:tags).and_return([])
      end

      it 'does nothing' do
        expect(repository).not_to receive(:delete_tag)

        repository.delete_tags!
      end
    end

    context 'when there are tags' do
      before do
        tag1 = ContainerRegistry::Tag.new(repository, 'tag1')
        tag2 = ContainerRegistry::Tag.new(repository, 'tag2')
        allow(tag1).to receive(:digest).and_return('123')
        allow(tag2).to receive(:digest).and_return('234')

        allow(repository).to receive(:tags).and_return([tag1, tag2])
      end

      context 'when action succeeds' do
        it 'returns status that indicates success' do
          expect(repository.client)
            .to receive(:delete_repository_tag_by_digest)
            .twice
            .and_return(true)

          expect(repository.delete_tags!).to be_truthy
        end
      end

      context 'when action fails' do
        it 'returns status that indicates failure' do
          expect(repository.client)
            .to receive(:delete_repository_tag_by_digest)
            .twice
            .and_return(false)

          expect(repository.delete_tags!).to be_falsey
        end
      end
    end
  end

  describe '#delete_tag' do
    let(:repository) do
      create(
        :container_repository,
        name: 'my_image',
        tags: { latest: '123', rc1: '234' },
        project: project
      )
    end

    context 'when action succeeds' do
      it 'returns status that indicates success' do
        expect(repository.client)
          .to receive(:delete_repository_tag_by_digest)
          .with(repository.path, "latest")
          .and_return(true)

        expect(repository.delete_tag('latest')).to be_truthy
      end
    end

    context 'when action fails' do
      it 'returns status that indicates failure' do
        expect(repository.client)
          .to receive(:delete_repository_tag_by_digest)
          .with(repository.path, "latest")
          .and_return(false)

        expect(repository.delete_tag('latest')).to be_falsey
      end
    end
  end

  describe '#location' do
    context 'when registry is running on a custom port' do
      before do
        stub_container_registry_config(
          enabled: true,
          api_url: 'http://registry.gitlab:5000',
          host_port: 'registry.gitlab:5000'
        )
      end

      it 'returns a full location of the repository' do
        expect(repository.location)
          .to eq 'registry.gitlab:5000/group/test/my_image'
      end
    end
  end

  describe '#root_repository?' do
    context 'when repository is a root repository' do
      let(:repository) { create(:container_repository, :root) }

      it 'returns true' do
        expect(repository).to be_root_repository
      end
    end

    context 'when repository is not a root repository' do
      it 'returns false' do
        expect(repository).not_to be_root_repository
      end
    end
  end

  describe '#start_expiration_policy!' do
    subject { repository.start_expiration_policy! }

    before do
      repository.update_column(:last_cleanup_deleted_tags_count, 10)
    end

    it 'sets the expiration policy started at to now' do
      freeze_time do
        expect { subject }
          .to change { repository.expiration_policy_started_at }.from(nil).to(Time.zone.now)
          .and change { repository.expiration_policy_cleanup_status }.from('cleanup_unscheduled').to('cleanup_ongoing')
          .and change { repository.last_cleanup_deleted_tags_count }.from(10).to(nil)
      end
    end
  end

  describe '#size' do
    subject { repository.size }

    context 'when the Gitlab API is supported' do
      before do
        expect(repository.gitlab_api_client).to receive(:supports_gitlab_api?).and_return(true)
        expect(repository.gitlab_api_client).to receive(:repository_details).with(repository.path, sizing: :self).and_return(response)
      end

      context 'with a size_bytes field' do
        let(:response) { { 'size_bytes' => 12345 } }

        it { is_expected.to eq(12345) }
      end

      context 'without a size_bytes field' do
        let(:response) { { 'foo' => 'bar' } }

        it { is_expected.to eq(nil) }
      end
    end

    context 'when the Gitlab API is not supported' do
      before do
        expect(repository.gitlab_api_client).to receive(:supports_gitlab_api?).and_return(false)
        expect(repository.gitlab_api_client).not_to receive(:repository_details)
      end

      it { is_expected.to eq(nil) }
    end
  end

  describe '#set_delete_ongoing_status', :freeze_time do
    let(:repository) { create(:container_repository, next_delete_attempt_at: Time.zone.now) }

    subject { repository.set_delete_ongoing_status }

    it 'updates deletion status attributes' do
      expect { subject }.to change(repository, :status).from(nil).to('delete_ongoing')
                              .and change(repository, :delete_started_at).from(nil).to(Time.zone.now)
                              .and change(repository, :status_updated_at).from(nil).to(Time.zone.now)
                              .and change(repository, :next_delete_attempt_at).to(nil)
    end
  end

  describe '#set_delete_scheduled_status', :freeze_time do
    subject { repository.set_delete_scheduled_status }

    let_it_be_with_reload(:repository) do
      create(
        :container_repository,
        :status_delete_ongoing,
        delete_started_at: 3.minutes.ago
      )
    end

    where(:current_failed_count, :new_failed_count, :minutes_delay) do
      0 |  1  | 1
      1 |  2  | 2
      2 |  3  | 4
      3 |  4  | 8
      4 |  5  | 16
      5 |  6  | 32
    end

    with_them do
      before do
        repository.update!(failed_deletion_count: current_failed_count)
      end

      it 'updates delete attributes' do
        expect { subject }.to change(repository, :status).from('delete_ongoing').to('delete_scheduled')
                                .and change(repository, :delete_started_at).to(nil)
                                .and change(repository, :failed_deletion_count).from(current_failed_count).to(new_failed_count)
                                .and change(repository, :next_delete_attempt_at).to(minutes_delay.minute.from_now)

        expect(repository.status_updated_at).to eq(Time.zone.now)
      end
    end
  end

  describe '#set_delete_failed_status', :freeze_time do
    let_it_be(:repository) { create(:container_repository, :status_delete_ongoing, delete_started_at: 3.minutes.ago) }

    subject { repository.set_delete_failed_status }

    it 'updates delete attributes' do
      expect { subject }.to change(repository, :status).from('delete_ongoing').to('delete_failed')
                              .and change(repository, :delete_started_at).to(nil)
                              .and change(repository, :status_updated_at).to(Time.zone.now)
    end
  end

  describe '#status_updated_at', :freeze_time do
    let_it_be_with_reload(:repository) { create(:container_repository) }

    %i[delete_scheduled delete_ongoing delete_failed].each do |status|
      context "when status is updated to #{status}" do
        it 'updates status_changed_at' do
          expect { repository.update!(status: status) }.to change(repository, :status_updated_at).from(nil).to(Time.zone.now)
        end
      end
    end

    context 'when status is not changed' do
      it 'does not update status_changed_at' do
        repository.name = 'different-image'

        expect { repository.save! }.not_to change(repository, :status_updated_at)
      end
    end
  end

  describe '.pending_destruction' do
    let_it_be(:delete_failed_repository) { create(:container_repository, :status_delete_failed) }
    let_it_be(:delete_ongoing_repository) { create(:container_repository, :status_delete_ongoing) }
    let_it_be(:delete_scheduled_in_the_future) { create(:container_repository, :status_delete_scheduled, next_delete_attempt_at: 2.hours.from_now) }
    let_it_be(:delete_scheduled_in_the_past) { create(:container_repository, :status_delete_scheduled, next_delete_attempt_at: 2.hours.ago) }
    let_it_be(:delete_scheduled_no_next_delete_attempt_at) { create(:container_repository, :status_delete_scheduled, next_delete_attempt_at: nil) }

    it 'returns repositories that are delete_scheduled and next_delete_attempt_at is nil or has_passed' do
      expect(described_class.pending_destruction).to include(
        delete_scheduled_in_the_past,
        delete_scheduled_no_next_delete_attempt_at
      )
      expect(described_class.pending_destruction).not_to include(
        delete_failed_repository,
        delete_ongoing_repository,
        delete_scheduled_in_the_future
      )
    end
  end

  describe '.build_from_path' do
    let(:registry_path) do
      ContainerRegistry::Path.new(project.full_path + '/some/image')
    end

    let(:repository) do
      described_class.build_from_path(registry_path)
    end

    it 'fabricates repository assigned to a correct project' do
      expect(repository.project).to eq project
    end

    it 'fabricates repository with a correct name' do
      expect(repository.name).to eq 'some/image'
    end

    it 'is not persisted' do
      expect(repository).not_to be_persisted
    end
  end

  describe '.find_or_create_from_path!' do
    let(:repository) do
      described_class.find_or_create_from_path!(ContainerRegistry::Path.new(path))
    end

    let(:repository_path) { ContainerRegistry::Path.new(path) }

    context 'when received multi-level repository path' do
      let(:path) { project.full_path + '/some/image' }

      it 'fabricates repository assigned to a correct project' do
        expect(repository.project).to eq project
      end

      it 'fabricates repository with a correct name' do
        expect(repository.name).to eq 'some/image'
      end
    end

    context 'when path is too long' do
      let(:path) do
        project.full_path + '/a/b/c/d/e/f/g/h/i/j/k/l/n/o/p/s/t/u/x/y/z'
      end

      it 'does not create repository and raises error' do
        expect { repository }.to raise_error(
          ContainerRegistry::Path::InvalidRegistryPathError)
      end
    end

    context 'when received multi-level repository with nested groups' do
      let(:group) { create(:group, :nested, name: 'nested') }
      let(:path) { project.full_path + '/some/image' }

      it 'fabricates repository assigned to a correct project' do
        expect(repository.project).to eq project
      end

      it 'fabricates repository with a correct name' do
        expect(repository.name).to eq 'some/image'
      end

      it 'has path including a nested group' do
        expect(repository.path).to include 'nested/test/some/image'
      end
    end

    context 'when received root repository path' do
      let(:path) { project.full_path }

      it 'fabricates repository assigned to a correct project' do
        expect(repository.project).to eq project
      end

      it 'fabricates repository with an empty name' do
        expect(repository.name).to be_empty
      end
    end

    context 'when repository already exists' do
      let(:path) { project.full_path + '/some/image' }

      it 'returns the existing repository' do
        container_repository = create(:container_repository, project: project, name: 'some/image')

        expect(repository.id).to eq(container_repository.id)
      end
    end

    context 'when many of the same repository are created at the same time' do
      let(:path) { ContainerRegistry::Path.new(project.full_path + '/some/image') }

      it 'does not throw validation errors and only creates one repository' do
        expect { repository_creation_race(path) }.to change { described_class.count }.by(1)
      end

      it 'retrieves a persisted repository for all concurrent calls' do
        repositories = repository_creation_race(path).map(&:value)

        expect(repositories).to all(be_persisted)
      end
    end

    def repository_creation_race(path)
      # create a race condition - structure from https://blog.arkency.com/2015/09/testing-race-conditions/
      wait_for_it = true

      threads = Array.new(10) do |i|
        Thread.new do
          true while wait_for_it

          described_class.find_or_create_from_path!(path)
        end
      end
      wait_for_it = false
      threads.each(&:join)
    end
  end

  describe '.find_by_path' do
    let_it_be(:container_repository) { create(:container_repository) }
    let_it_be(:repository_path) { container_repository.project.full_path }

    let(:path) { ContainerRegistry::Path.new(repository_path + '/' + container_repository.name) }

    subject { described_class.find_by_path(path) }

    context 'when repository exists' do
      it 'finds the repository' do
        expect(subject).to eq(container_repository)
      end
    end

    context 'when repository does not exist' do
      let(:path) { ContainerRegistry::Path.new(repository_path + '/some/image') }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end

  describe '.find_by_path!' do
    let_it_be(:container_repository) { create(:container_repository) }
    let_it_be(:repository_path) { container_repository.project.full_path }

    let(:path) { ContainerRegistry::Path.new(repository_path + '/' + container_repository.name) }

    subject { described_class.find_by_path!(path) }

    context 'when repository exists' do
      it 'finds the repository' do
        expect(subject).to eq(container_repository)
      end
    end

    context 'when repository does not exist' do
      let(:path) { ContainerRegistry::Path.new(repository_path + '/some/image') }

      it 'raises an exception' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '.build_root_repository' do
    let(:repository) do
      described_class.build_root_repository(project)
    end

    it 'fabricates a root repository object' do
      expect(repository).to be_root_repository
    end

    it 'assignes it to the correct project' do
      expect(repository.project).to eq project
    end

    it 'does not persist it' do
      expect(repository).not_to be_persisted
    end
  end

  describe '.for_group_and_its_subgroups' do
    subject { described_class.for_group_and_its_subgroups(test_group) }

    context 'in a group' do
      let(:test_group) { group }

      it { is_expected.to contain_exactly(repository) }
    end

    context 'with a subgroup' do
      let_it_be(:test_group) { create(:group) }
      let_it_be(:another_project) { create(:project, path: 'test', group: test_group) }
      let_it_be(:project3) { create(:project, :container_registry_disabled, path: 'test3', group: test_group) }

      let_it_be(:another_repository) do
        create(:container_repository, name: 'my_image', project: another_project)
      end

      let_it_be(:repository3) do
        create(:container_repository, name: 'my_image3', project: project3)
      end

      before do
        allow(group).to receive(:first_project_with_container_registry_tags).and_return(nil)

        group.parent = test_group
        group.save!
      end

      it { is_expected.to contain_exactly(repository, another_repository) }
    end

    context 'group without container_repositories' do
      let(:test_group) { create(:group) }

      it { is_expected.to eq([]) }
    end
  end

  describe '.search_by_name' do
    let!(:another_repository) do
      create(:container_repository, name: 'my_foo_bar', project: project)
    end

    subject { described_class.search_by_name('my_image') }

    it { is_expected.to contain_exactly(repository) }
  end

  describe '.for_project_id' do
    subject { described_class.for_project_id(project.id) }

    it { is_expected.to contain_exactly(repository) }
  end

  describe '.expiration_policy_started_at_nil_or_before' do
    let_it_be(:repository1) { create(:container_repository, expiration_policy_started_at: nil) }
    let_it_be(:repository2) { create(:container_repository, expiration_policy_started_at: 1.day.ago) }
    let_it_be(:repository3) { create(:container_repository, expiration_policy_started_at: 2.hours.ago) }
    let_it_be(:repository4) { create(:container_repository, expiration_policy_started_at: 1.week.ago) }

    subject { described_class.expiration_policy_started_at_nil_or_before(3.hours.ago) }

    it { is_expected.to contain_exactly(repository1, repository2, repository4) }
  end

  describe '.with_stale_ongoing_cleanup' do
    let_it_be(:repository1) { create(:container_repository, :cleanup_ongoing, expiration_policy_started_at: 1.day.ago) }
    let_it_be(:repository2) { create(:container_repository, :cleanup_ongoing, expiration_policy_started_at: 25.minutes.ago) }
    let_it_be(:repository3) { create(:container_repository, :cleanup_ongoing, expiration_policy_started_at: 1.week.ago) }
    let_it_be(:repository4) { create(:container_repository, :cleanup_unscheduled, expiration_policy_started_at: 25.minutes.ago) }

    subject { described_class.with_stale_ongoing_cleanup(27.minutes.ago) }

    it { is_expected.to contain_exactly(repository1, repository3) }
  end

  describe '.with_stale_delete_at' do
    let_it_be(:repository1) { create(:container_repository, delete_started_at: 1.day.ago) }
    let_it_be(:repository2) { create(:container_repository, delete_started_at: 25.minutes.ago) }
    let_it_be(:repository3) { create(:container_repository, delete_started_at: 1.week.ago) }

    subject { described_class.with_stale_delete_at(27.minutes.ago) }

    it { is_expected.to contain_exactly(repository1, repository3) }
  end

  describe '.waiting_for_cleanup' do
    let_it_be(:repository_cleanup_scheduled) { create(:container_repository, :cleanup_scheduled) }
    let_it_be(:repository_cleanup_unfinished) { create(:container_repository, :cleanup_unfinished) }
    let_it_be(:repository_cleanup_ongoing) { create(:container_repository, :cleanup_ongoing) }

    subject { described_class.waiting_for_cleanup }

    it { is_expected.to contain_exactly(repository_cleanup_scheduled, repository_cleanup_unfinished) }
  end

  describe '.exists_by_path?' do
    it 'returns true for known container repository paths' do
      path = ContainerRegistry::Path.new("#{project.full_path}/#{repository.name}")
      expect(described_class.exists_by_path?(path)).to be_truthy
    end

    it 'returns false for unknown container repository paths' do
      path = ContainerRegistry::Path.new('you/dont/know/me')
      expect(described_class.exists_by_path?(path)).to be_falsey
    end
  end

  describe '.with_enabled_policy' do
    let_it_be(:repository) { create(:container_repository) }
    let_it_be(:repository2) { create(:container_repository) }

    subject { described_class.with_enabled_policy }

    before do
      repository.project.container_expiration_policy.update!(enabled: true)
    end

    it { is_expected.to eq([repository]) }
  end

  context 'with repositories' do
    let_it_be_with_reload(:repository) { create(:container_repository, :cleanup_unscheduled) }
    let_it_be(:other_repository) { create(:container_repository, :cleanup_unscheduled) }

    let(:policy) { repository.project.container_expiration_policy }

    before do
      ContainerExpirationPolicy.update_all(enabled: true)
    end

    describe '.requiring_cleanup' do
      subject { described_class.requiring_cleanup }

      context 'with next_run_at in the future' do
        before do
          policy.update_column(:next_run_at, 10.minutes.from_now)
        end

        it { is_expected.to eq([]) }
      end

      context 'with next_run_at in the past' do
        before do
          policy.update_column(:next_run_at, 10.minutes.ago)
        end

        it { is_expected.to eq([repository]) }
      end

      context 'with repository cleanup started at after policy next run at' do
        before do
          repository.update!(expiration_policy_started_at: policy.next_run_at + 5.minutes)
        end

        it { is_expected.to eq([]) }
      end
    end

    describe '.with_unfinished_cleanup' do
      subject { described_class.with_unfinished_cleanup }

      it { is_expected.to eq([]) }

      context 'with an unfinished repository' do
        before do
          repository.cleanup_unfinished!
        end

        it { is_expected.to eq([repository]) }
      end
    end
  end

  describe '#registry' do
    it 'caches the client' do
      registry = repository.registry
      registry1 = repository.registry
      registry2 = nil

      travel_to(Time.current + Gitlab::CurrentSettings.container_registry_token_expire_delay.minutes) do
        registry2 = repository.registry
      end

      expect(registry1.object_id).to be(registry.object_id)
      expect(registry2.object_id).not_to be(registry.object_id)
    end
  end
end
