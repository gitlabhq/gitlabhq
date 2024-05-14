# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Harbor::Query do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:harbor_integration) { create(:harbor_integration) }

  let(:params) { {} }

  subject(:query) { described_class.new(harbor_integration, ActionController::Parameters.new(params)) }

  describe 'Validations' do
    context 'page' do
      context 'with valid page' do
        let(:params) { { page: 1 } }

        it 'initialize successfully' do
          expect(query.valid?).to eq(true)
        end
      end

      context 'with invalid page' do
        let(:params) { { page: -1 } }

        it 'initialize failed' do
          expect(query.valid?).to eq(false)
        end
      end
    end

    context 'limit' do
      context 'with valid limit' do
        let(:params) { { limit: 1 } }

        it 'initialize successfully' do
          expect(query.valid?).to eq(true)
        end
      end

      context 'with invalid limit' do
        context 'with limit less than 0' do
          let(:params) { { limit: -1 } }

          it 'initialize failed' do
            expect(query.valid?).to eq(false)
          end
        end

        context 'with limit greater than 25' do
          let(:params) { { limit: 26 } }

          it 'initialize failed' do
            expect(query.valid?).to eq(false)
          end
        end
      end
    end

    context 'repository_id' do
      context 'with valid repository_id' do
        let(:params) { { repository_id: 'test' } }

        it 'initialize successfully' do
          expect(query.valid?).to eq(true)
        end
      end

      context 'with invalid repository_id' do
        let(:params) { { repository_id: 'test@@' } }

        it 'initialize failed' do
          expect(query.valid?).to eq(false)
        end
      end
    end

    context 'artifact_id' do
      context 'with valid artifact_id' do
        let(:params) { { artifact_id: 'test' } }

        it 'initialize successfully' do
          expect(query.valid?).to eq(true)
        end
      end

      context 'with invalid artifact_id' do
        let(:params) { { artifact_id: 'test@@' } }

        it 'initialize failed' do
          expect(query.valid?).to eq(false)
        end
      end
    end

    context 'sort' do
      context 'with valid sort' do
        let(:params) { { sort: 'creation_time desc' } }

        it 'initialize successfully' do
          expect(query.valid?).to eq(true)
        end
      end

      context 'with invalid sort' do
        let(:params) { { sort: 'blabla desc' } }

        it 'initialize failed' do
          expect(query.valid?).to eq(false)
        end
      end
    end

    context 'search' do
      where(:search_param, :is_valid) do
        "name=desc"                  | true
        "name=value1,name=value-2"   | true
        "name=value1,name=value_2"   | false
        "name=desc,key=value"        | false
        "name=value1, name=value2"   | false
        "name"                       | false
      end

      with_them do
        let(:params) { { search: search_param } }

        it "validates according to the regex" do
          expect(query.valid?).to eq(is_valid)
        end
      end
    end
  end

  describe '#repositories' do
    let(:response) { { total_count: 0, repositories: [] } }

    def expect_query_option_include(expected_params)
      expect_next_instance_of(Gitlab::Harbor::Client) do |client|
        expect(client).to receive(:get_repositories)
          .with(hash_including(expected_params))
          .and_return(response)
      end

      query.repositories
    end

    context 'when params is {}' do
      it 'fills default params' do
        expect_query_option_include(page_size: 10, page: 1)
      end
    end

    context 'when params contains options' do
      let(:params) { { search: 'name=bu', sort: 'creation_time desc', limit: 20, page: 3 } }

      it 'fills params with standard of Harbor' do
        expect_query_option_include(q: 'name=~bu', sort: '-creation_time', page_size: 20, page: 3)
      end
    end

    context 'when params contains invalid sort option' do
      let(:params) { { search: 'name=bu', sort: 'blabla desc', limit: 20, page: 3 } }

      it 'ignores invalid sort params' do
        expect(query.valid?).to eq(false)
      end
    end

    context 'when client.get_repositories returns data' do
      let(:response_with_data) do
        {
          total_count: 1,
          body:
          [
            {
              id: 3,
              name: "testproject/thirdbusybox",
              artifact_count: 1,
              creation_time: "2022-03-15T07:12:14.479Z",
              update_time: "2022-03-15T07:12:14.479Z",
              project_id: 3,
              pull_count: 0
            }.with_indifferent_access
          ]
        }
      end

      it 'returns the right repositories data' do
        expect_next_instance_of(Gitlab::Harbor::Client) do |client|
          expect(client).to receive(:get_repositories)
            .with(hash_including(page_size: 10, page: 1))
            .and_return(response_with_data)
        end

        expect(query.repositories.first).to include(
          name: "testproject/thirdbusybox",
          artifact_count: 1
        )
      end
    end
  end

  describe '#artifacts' do
    let(:response) { { total_count: 0, artifacts: [] } }

    def expect_query_option_include(expected_params)
      expect_next_instance_of(Gitlab::Harbor::Client) do |client|
        expect(client).to receive(:get_artifacts)
          .with(hash_including(expected_params))
          .and_return(response)
      end

      query.artifacts
    end

    context 'when params is {}' do
      it 'fills default params' do
        expect_query_option_include(page_size: 10, page: 1)
      end
    end

    context 'when params contains options' do
      let(:params) do
        { search: 'tags=1', repository_id: 'jihuprivate', sort: 'creation_time desc', limit: 20, page: 3 }
      end

      it 'fills params with standard of Harbor' do
        expect_query_option_include(q: 'tags=~1', sort: '-creation_time', page_size: 20, page: 3)
      end
    end

    context 'when params contains invalid sort option' do
      let(:params) { { search: 'tags=1', repository_id: 'jihuprivate', sort: 'blabla desc', limit: 20, page: 3 } }

      it 'ignores invalid sort params' do
        expect(query.valid?).to eq(false)
      end
    end

    context 'when client.get_artifacts returns data' do
      let(:response_with_data) do
        {
          total_count: 1,
          body:
          [
            {
              digest: "sha256:14d4f50961544fdb669075c442509f194bdc4c0e344bde06e35dbd55af842a38",
              icon: "sha256:0048162a053eef4d4ce3fe7518615bef084403614f8bca43b40ae2e762e11e06",
              id: 5,
              project_id: 14,
              push_time: "2022-03-22T09:04:56.170Z",
              repository_id: 5,
              size: 774790,
              tags: [
                {
                  artifact_id: 5,
                  id: 7,
                  immutable: false,
                  name: "2",
                  pull_time: "0001-01-01T00:00:00.000Z",
                  push_time: "2022-03-22T09:05:04.844Z",
                  repository_id: 5
                },
                {
                  artifact_id: 5,
                  id: 6,
                  immutable: false,
                  name: "1",
                  pull_time: "0001-01-01T00:00:00.000Z",
                  push_time: "2022-03-22T09:04:56.186Z",
                  repository_id: 5
                }
              ],
              type: "IMAGE"
            }.with_indifferent_access
          ]
        }
      end

      it 'returns the right artifacts data' do
        expect_next_instance_of(Gitlab::Harbor::Client) do |client|
          expect(client).to receive(:get_artifacts)
            .with(hash_including(page_size: 10, page: 1))
            .and_return(response_with_data)
        end

        artifact = query.artifacts.first

        expect(artifact).to include(
          digest: "sha256:14d4f50961544fdb669075c442509f194bdc4c0e344bde06e35dbd55af842a38",
          push_time: "2022-03-22T09:04:56.170Z"
        )
        expect(artifact["tags"].size).to eq(2)
      end
    end
  end

  describe '#tags' do
    let(:response) { { total_count: 0, tags: [] } }

    def expect_query_option_include(expected_params)
      expect_next_instance_of(Gitlab::Harbor::Client) do |client|
        expect(client).to receive(:get_tags)
          .with(hash_including(expected_params))
          .and_return(response)
      end

      query.tags
    end

    context 'when params is {}' do
      it 'fills default params' do
        expect_query_option_include(page_size: 10, page: 1)
      end
    end

    context 'when params contains options' do
      let(:params) { { repository_id: 'jihuprivate', sort: 'creation_time desc', limit: 20, page: 3 } }

      it 'fills params with standard of Harbor' do
        expect_query_option_include(sort: '-creation_time', page_size: 20, page: 3)
      end
    end

    context 'when params contains invalid sort option' do
      let(:params) { { repository_id: 'jihuprivate', artifact_id: 'test', sort: 'blabla desc', limit: 20, page: 3 } }

      it 'ignores invalid sort params' do
        expect(query.valid?).to eq(false)
      end
    end

    context 'when client.get_tags returns data' do
      let(:response_with_data) do
        {
          total_count: 2,
          body:
          [
            {
              artifact_id: 5,
              id: 7,
              immutable: false,
              name: "2",
              pull_time: "0001-01-01T00:00:00.000Z",
              push_time: "2022-03-22T09:05:04.844Z",
              repository_id: 5
            },
            {
              artifact_id: 5,
              id: 6,
              immutable: false,
              name: "1",
              pull_time: "0001-01-01T00:00:00.000Z",
              push_time: "2022-03-22T09:04:56.186Z",
              repository_id: 5
            }.with_indifferent_access
          ]
        }
      end

      it 'returns the right tags data' do
        expect_next_instance_of(Gitlab::Harbor::Client) do |client|
          expect(client).to receive(:get_tags)
            .with(hash_including(page_size: 10, page: 1))
            .and_return(response_with_data)
        end

        tag = query.tags.first

        expect(tag).to include(
          immutable: false,
          push_time: "2022-03-22T09:05:04.844Z"
        )
      end
    end
  end
end
