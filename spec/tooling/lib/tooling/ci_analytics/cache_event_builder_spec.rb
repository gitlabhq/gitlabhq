# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../../tooling/lib/tooling/ci_analytics/cache_event_builder'

RSpec.describe Tooling::CiAnalytics::CacheEventBuilder, feature_category: :tooling do
  let(:sample_cache_data) do
    {
      cache_key: 'ruby-gems-debian-bookworm-ruby-3.3.8-gemfile-Gemfile-22',
      cache_type: 'ruby-gems',
      cache_operation: 'pull',
      cache_result: 'hit',
      duration: 5.2,
      cache_size_bytes: 1024000,
      operation_command: 'bundle install',
      operation_duration: 3.5,
      operation_success: true
    }
  end

  let(:ci_env) do
    {
      job_id: '12345',
      job_name: 'rspec-unit pg16',
      pipeline_id: '67890',
      project_id: '278964',
      merge_request_iid: '199241',
      merge_request_target_branch: 'master',
      pipeline_source: 'merge_request_event',
      ref: 'feature-branch',
      job_url: 'https://gitlab.com/gitlab-org/gitlab/-/jobs/12345'
    }
  end

  let(:builder) { described_class.new(ci_env) }

  before do
    allow(Time).to receive(:now).and_return(Time.parse('2025-07-25T10:30:00Z'))
  end

  describe '#build_bigquery_event' do
    it 'includes base event data' do
      result = builder.build_bigquery_event(sample_cache_data)

      expect(result[:job_id]).to eq(12345)
      expect(result[:job_name]).to eq('rspec-unit pg16')
      expect(result[:pipeline_id]).to eq(67890)
      expect(result[:project_id]).to eq(278964)
      expect(result[:cache_key]).to eq('ruby-gems-debian-bookworm-ruby-3.3.8-gemfile-Gemfile-22')
      expect(result[:cache_type]).to eq('ruby-gems')
    end

    it 'includes BigQuery-specific fields' do
      result = builder.build_bigquery_event(sample_cache_data)

      expect(result[:job_url]).to eq('https://gitlab.com/gitlab-org/gitlab/-/jobs/12345')
      expect(result[:created_at]).to eq('2025-07-25T10:30:00Z')
      expect(Time).to have_received(:now)
    end

    it 'preserves all cache data fields' do
      result = builder.build_bigquery_event(sample_cache_data)

      expect(result[:cache_operation]).to eq('pull')
      expect(result[:cache_result]).to eq('hit')
      expect(result[:cache_operation_duration_seconds]).to eq(5.2)
      expect(result[:cache_size_bytes]).to eq(1024000)
      expect(result[:operation_command]).to eq('bundle install')
      expect(result[:operation_duration_seconds]).to eq(3.5)
      expect(result[:operation_success]).to eq("true")
    end

    context 'when job_url is not set' do
      let(:builder_without_job_url) { described_class.new(ci_env.merge(job_url: nil)) }

      it 'handles missing job URL' do
        result = builder_without_job_url.build_bigquery_event(sample_cache_data)

        expect(result[:job_url]).to be_nil
      end
    end
  end

  describe '#build_internal_event_properties' do
    it 'includes base event data' do
      result = builder.build_internal_event_properties(sample_cache_data)

      expect(result[:extra_properties][:job_id]).to eq(12345)
      expect(result[:extra_properties][:job_name]).to eq('rspec-unit pg16')
      expect(result[:extra_properties][:cache_key]).to eq('ruby-gems-debian-bookworm-ruby-3.3.8-gemfile-Gemfile-22')
    end

    it 'includes internal event specific fields' do
      result = builder.build_internal_event_properties(sample_cache_data)

      expect(result[:label]).to eq('hit')
      expect(result[:property]).to eq('ruby-gems')
      expect(result[:value]).to eq(5.2)
    end

    it 'excludes BigQuery-specific fields' do
      result = builder.build_internal_event_properties(sample_cache_data)

      expect(result[:extra_properties]).not_to have_key(:job_url)
      expect(result[:extra_properties]).not_to have_key(:created_at)
      expect(result).not_to have_key(:job_url)
      expect(result).not_to have_key(:project_id)
      expect(result).not_to have_key(:created_at)
    end

    it 'rounds duration value to 2 decimal places' do
      cache_data_with_long_duration = sample_cache_data.merge(duration: 5.123456789)

      result = builder.build_internal_event_properties(cache_data_with_long_duration)

      expect(result[:value]).to eq(5.12)
    end

    context 'when duration is nil' do
      it 'handles nil duration gracefully' do
        cache_data_without_duration = sample_cache_data.merge(duration: nil)

        result = builder.build_internal_event_properties(cache_data_without_duration)

        expect(result[:value]).to be_nil
      end
    end
  end

  describe '#base_event_data' do
    it 'converts string environment variables to integers' do
      result = builder.send(:base_event_data, sample_cache_data)

      expect(result[:job_id]).to eq(12345)
      expect(result[:pipeline_id]).to eq(67890)
      expect(result[:project_id]).to eq(278964)
      expect(result[:merge_request_iid]).to eq(199241)
      # String fields remain strings
      expect(result[:job_name]).to eq('rspec-unit pg16')
    end

    it 'includes all CI environment variables' do
      result = builder.send(:base_event_data, sample_cache_data)

      expect(result[:merge_request_target_branch]).to eq('master')
      expect(result[:pipeline_source]).to eq('merge_request_event')
      expect(result[:ref]).to eq('feature-branch')
    end

    it 'includes all cache data fields' do
      result = builder.send(:base_event_data, sample_cache_data)

      expect(result[:cache_key]).to eq('ruby-gems-debian-bookworm-ruby-3.3.8-gemfile-Gemfile-22')
      expect(result[:cache_type]).to eq('ruby-gems')
      expect(result[:cache_operation]).to eq('pull')
      expect(result[:cache_result]).to eq('hit')
      expect(result[:cache_operation_duration_seconds]).to eq(5.2)
      expect(result[:cache_size_bytes]).to eq(1024000)
      expect(result[:operation_command]).to eq('bundle install')
      expect(result[:operation_duration_seconds]).to eq(3.5)
      expect(result[:operation_success]).to eq("true")
    end

    context 'with empty merge request IID' do
      let(:builder_with_empty_mr_iid) { described_class.new(ci_env.merge(merge_request_iid: '')) }

      it 'converts empty string to nil' do
        result = builder_with_empty_mr_iid.send(:base_event_data, sample_cache_data)

        expect(result[:merge_request_iid]).to be_nil
      end
    end

    context 'with nil merge request IID' do
      let(:builder_with_nil_mr_iid) { described_class.new(ci_env.merge(merge_request_iid: nil)) }

      it 'keeps nil as nil' do
        result = builder_with_nil_mr_iid.send(:base_event_data, sample_cache_data)

        expect(result[:merge_request_iid]).to be_nil
      end
    end

    context 'with missing environment variables' do
      let(:builder_with_minimal_env) do
        described_class.new({
          job_id: nil,
          job_name: nil,
          pipeline_id: nil,
          project_id: nil,
          merge_request_iid: nil,
          merge_request_target_branch: nil,
          pipeline_source: nil,
          ref: nil,
          job_url: nil
        })
      end

      it 'handles missing environment variables gracefully' do
        result = builder_with_minimal_env.send(:base_event_data, sample_cache_data)

        expect(result[:job_id]).to eq(0)
        expect(result[:pipeline_id]).to eq(0)
        expect(result[:project_id]).to eq(0)
        expect(result[:merge_request_target_branch]).to be_nil
        expect(result[:pipeline_source]).to be_nil
        expect(result[:ref]).to be_nil
      end
    end

    context 'with minimal cache data' do
      let(:minimal_cache_data) do
        {
          cache_key: 'test-cache',
          cache_type: 'test',
          cache_operation: 'pull',
          cache_result: 'miss'
        }
      end

      it 'handles missing optional cache fields' do
        result = builder.send(:base_event_data, minimal_cache_data)

        expect(result[:cache_key]).to eq('test-cache')
        expect(result[:cache_type]).to eq('test')
        expect(result[:cache_operation]).to eq('pull')
        expect(result[:cache_result]).to eq('miss')
        expect(result[:cache_operation_duration_seconds]).to be_nil
        expect(result[:cache_size_bytes]).to be_nil
        expect(result[:operation_command]).to be_nil
        expect(result[:operation_duration_seconds]).to be_nil
        expect(result[:operation_success]).to be_nil
      end
    end
  end

  describe 'integration scenarios' do
    context 'with master branch pipeline' do
      let(:master_branch_builder) do
        described_class.new(ci_env.merge(
          merge_request_iid: '',
          merge_request_target_branch: nil,
          pipeline_source: 'push',
          ref: 'master'
        ))
      end

      it 'builds appropriate data for master branch' do
        bigquery_result = master_branch_builder.build_bigquery_event(sample_cache_data)
        internal_result = master_branch_builder.build_internal_event_properties(sample_cache_data)

        expect(bigquery_result[:merge_request_iid]).to be_nil
        expect(bigquery_result[:merge_request_target_branch]).to be_nil
        expect(bigquery_result[:pipeline_source]).to eq('push')
        expect(bigquery_result[:ref]).to eq('master')

        expect(internal_result[:extra_properties][:merge_request_iid]).to be_nil
        expect(internal_result[:extra_properties][:merge_request_target_branch]).to be_nil
        expect(internal_result[:extra_properties][:pipeline_source]).to eq('push')
        expect(internal_result[:extra_properties][:ref]).to eq('master')
      end
    end

    context 'with cache creation data' do
      let(:cache_creation_data) do
        {
          cache_key: 'go-pkg-debian-bookworm-22',
          cache_type: 'go',
          cache_operation: 'push',
          cache_result: 'created',
          duration: 118.0,
          cache_size_bytes: nil,
          operation_command: nil,
          operation_duration: nil,
          operation_success: nil
        }
      end

      it 'handles cache creation scenarios correctly' do
        bigquery_result = builder.build_bigquery_event(cache_creation_data)
        internal_result = builder.build_internal_event_properties(cache_creation_data)

        expect(bigquery_result[:cache_operation]).to eq('push')
        expect(bigquery_result[:cache_result]).to eq('created')
        expect(bigquery_result[:cache_operation_duration_seconds]).to eq(118.0)

        expect(internal_result[:label]).to eq('created')
        expect(internal_result[:property]).to eq('go')
        expect(internal_result[:value]).to eq(118.0)
      end
    end
  end
end
