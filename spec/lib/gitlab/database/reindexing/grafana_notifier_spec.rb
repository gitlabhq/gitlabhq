# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Reindexing::GrafanaNotifier do
  include Database::DatabaseHelpers

  let(:api_key) { "foo" }
  let(:api_url) { "http://bar" }
  let(:additional_tag) { "some-tag" }

  let(:action) { create(:reindex_action) }

  before do
    swapout_view_for_table(:postgres_indexes, connection: ApplicationRecord.connection)
  end

  let(:headers) do
    {
      'Content-Type': 'application/json',
      Authorization: "Bearer #{api_key}"
    }
  end

  let(:response) { double('response', success?: true) }

  def expect_api_call(payload)
    expect(Gitlab::HTTP).to receive(:post).with(
      "#{api_url}/api/annotations", body: payload.to_json, headers: headers, allow_local_requests: true
    ).and_return(response)
  end

  shared_examples_for 'interacting with Grafana annotations API' do
    it 'POSTs a JSON payload' do
      expect_api_call(payload)

      expect(subject).to be_truthy
    end

    context 'on error' do
      it 'does not raise the error and returns false' do
        allow(Gitlab::HTTP).to receive(:post).and_raise('something went wrong')

        expect(subject).to be_falsey
      end

      context 'when request was not successful' do
        it 'returns false' do
          expect_api_call(payload)
          allow(response).to receive(:success?).and_return(false)

          expect(subject).to be_falsey
        end
      end
    end

    context 'without api_key' do
      let(:api_key) { '' }

      it 'does not post anything' do
        expect(Gitlab::HTTP).not_to receive(:post)

        expect(subject).to be_falsey
      end
    end

    context 'without api_url' do
      let(:api_url) { '' }

      it 'does not post anything' do
        expect(Gitlab::HTTP).not_to receive(:post)

        expect(subject).to be_falsey
      end
    end
  end

  describe '#notify_start' do
    context 'when Grafana is configured using application settings' do
      subject { described_class.new.notify_start(action) }

      let(:payload) do
        {
          time: (action.action_start.utc.to_f * 1000).to_i,
          tags: ['reindex', additional_tag, action.index.tablename, action.index.name],
          text: "Started reindexing of #{action.index.name} on #{action.index.tablename}"
        }
      end

      before do
        stub_application_setting(database_grafana_api_key: api_key)
        stub_application_setting(database_grafana_api_url: api_url)
        stub_application_setting(database_grafana_tag: additional_tag)
      end

      it_behaves_like 'interacting with Grafana annotations API'
    end

    context 'when there is no additional tag' do
      subject { described_class.new(api_key: api_key, api_url: api_url, additional_tag: '').notify_start(action) }

      let(:payload) do
        {
          time: (action.action_start.utc.to_f * 1000).to_i,
          tags: ['reindex', action.index.tablename, action.index.name],
          text: "Started reindexing of #{action.index.name} on #{action.index.tablename}"
        }
      end

      it_behaves_like 'interacting with Grafana annotations API'
    end

    context 'additional tag is provided' do
      subject do
        described_class.new(api_key: api_key, api_url: api_url, additional_tag: additional_tag).notify_start(action)
      end

      let(:payload) do
        {
          time: (action.action_start.utc.to_f * 1000).to_i,
          tags: ['reindex', additional_tag, action.index.tablename, action.index.name],
          text: "Started reindexing of #{action.index.name} on #{action.index.tablename}"
        }
      end

      it_behaves_like 'interacting with Grafana annotations API'
    end
  end

  describe '#notify_end' do
    context 'when Grafana is configured using application settings' do
      subject { described_class.new.notify_end(action) }

      let(:payload) do
        {
          time: (action.action_start.utc.to_f * 1000).to_i,
          tags: ['reindex', additional_tag, action.index.tablename, action.index.name],
          text: "Finished reindexing of #{action.index.name} on #{action.index.tablename} (#{action.state})",
          timeEnd: (action.action_end.utc.to_f * 1000).to_i,
          isRegion: true
        }
      end

      before do
        stub_application_setting(database_grafana_api_key: api_key)
        stub_application_setting(database_grafana_api_url: api_url)
        stub_application_setting(database_grafana_tag: additional_tag)
      end

      it_behaves_like 'interacting with Grafana annotations API'
    end

    context 'when there is no additional tag' do
      subject { described_class.new(api_key: api_key, api_url: api_url, additional_tag: '').notify_end(action) }

      let(:payload) do
        {
          time: (action.action_start.utc.to_f * 1000).to_i,
          tags: ['reindex', action.index.tablename, action.index.name],
          text: "Finished reindexing of #{action.index.name} on #{action.index.tablename} (#{action.state})",
          timeEnd: (action.action_end.utc.to_f * 1000).to_i,
          isRegion: true
        }
      end

      it_behaves_like 'interacting with Grafana annotations API'
    end

    context 'additional tag is provided' do
      subject do
        described_class.new(api_key: api_key, api_url: api_url, additional_tag: additional_tag).notify_end(action)
      end

      let(:payload) do
        {
          time: (action.action_start.utc.to_f * 1000).to_i,
          tags: ['reindex', additional_tag, action.index.tablename, action.index.name],
          text: "Finished reindexing of #{action.index.name} on #{action.index.tablename} (#{action.state})",
          timeEnd: (action.action_end.utc.to_f * 1000).to_i,
          isRegion: true
        }
      end

      it_behaves_like 'interacting with Grafana annotations API'
    end
  end
end
