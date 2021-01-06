# frozen_string_literal: true

module Atlassian
  module Schemata
    class << self
      def build_info
        {
          'type' => 'object',
          'additionalProperties' => false,
          'required' => %w(
            schemaVersion pipelineId buildNumber updateSequenceNumber
            displayName url state issueKeys testInfo references
            lastUpdated
           ),
          'properties' => {
            'schemaVersion' => schema_version_type,
            'pipelineId' => { 'type' => 'string' },
            'buildNumber' => { 'type' => 'integer' },
            'updateSequenceNumber' => { 'type' => 'integer' },
            'displayName' => { 'type' => 'string' },
            'lastUpdated' => { 'type' => 'string' },
            'url' => { 'type' => 'string' },
            'state' => state_type,
            'issueKeys' => issue_keys_type,
            'testInfo' => {
              'type' => 'object',
              'required' => %w(totalNumber numberPassed numberFailed numberSkipped),
              'properties' => {
                'totalNumber' => { 'type' => 'integer' },
                'numberFailed' => { 'type' => 'integer' },
                'numberPassed' => { 'type' => 'integer' },
                'numberSkipped' => { 'type' => 'integer' }
              }
            },
            'references' => {
              'type' => 'array',
              'items' => {
                'type' => 'object',
                'required' => %w(commit ref),
                'properties' => {
                  'commit' => {
                    'type' => 'object',
                    'required' => %w(id repositoryUri),
                    'properties' => {
                      'id' => { 'type' => 'string' },
                      'repositoryUri' => { 'type' => 'string' }
                    }
                  },
                  'ref' => {
                    'type' => 'object',
                    'required' => %w(name uri),
                    'properties' => {
                      'name' => { 'type' => 'string' },
                      'uri' => { 'type' => 'string' }
                    }
                  }
                }
              }
            }
          }
        }
      end

      def deployment_info
        {
          'type' => 'object',
          'additionalProperties' => false,
          'required' => %w(
            deploymentSequenceNumber updateSequenceNumber
            associations displayName url description lastUpdated
            state pipeline environment
          ),
          'properties' => {
            'deploymentSequenceNumber' => { 'type' => 'integer' },
            'updateSequenceNumber' => { 'type' => 'integer' },
            'associations' => {
              'type' => 'array',
              'items' => association_type,
              'minItems' => 1
            },
            'displayName' => { 'type' => 'string' },
            'description' => { 'type' => 'string' },
            'label' => { 'type' => 'string' },
            'url' => { 'type' => 'string' },
            'lastUpdated' => { 'type' => 'string' },
            'state' => state_type,
            'pipeline' => pipeline_type,
            'environment' => environment_type,
            'schemaVersion' => schema_version_type
          }
        }
      end

      def environment_type
        {
          'type' => 'object',
          'additionalProperties' => false,
          'required' => %w(id displayName type),
          'properties' => {
            'id' => { 'type' => 'string', 'maxLength' => 255 },
            'displayName' => { 'type' => 'string', 'maxLength' => 255 },
            'type' => {
              'type' => 'string',
              'pattern' => '(unmapped|development|testing|staging|production)'
            }
          }
        }
      end

      def pipeline_type
        {
          'type' => 'object',
          'additionalProperties' => false,
          'required' => %w(id displayName url),
          'properties' => {
            'id' => { 'type' => 'string', 'maxLength' => 255 },
            'displayName' => { 'type' => 'string', 'maxLength' => 255 },
            'url' => { 'type' => 'string', 'maxLength' => 2000 }
          }
        }
      end

      def schema_version_type
        { 'type' => 'string', 'pattern' => '1.0' }
      end

      def state_type
        {
          'type' => 'string',
          'pattern' => '(pending|in_progress|successful|failed|cancelled)'
        }
      end

      def association_type
        {
          'type' => 'object',
          'additionalProperties' => false,
          'required' => %w(associationType values),
          'properties' => {
            'associationType' => {
              'type' => 'string',
              'pattern' => '(issueKeys|issueIdOrKeys)'
            },
            'values' => issue_keys_type
          }
        }
      end

      def issue_keys_type
        {
          'type' => 'array',
          'items' => { 'type' => 'string' },
          'minItems' => 1,
          'maxItems' => 100
        }
      end

      def deploy_info_payload
        payload('deployments', deployment_info)
      end

      def build_info_payload
        payload('builds', build_info)
      end

      def payload(key, schema)
        {
          'type' => 'object',
          'required' => ['providerMetadata', key],
          'properties' => {
            'providerMetadata' => provider_metadata,
            key => { 'type' => 'array', 'items' => schema }
          }
        }
      end

      def provider_metadata
        {
          'type' => 'object',
          'required' => %w(product),
          'properties' => { 'product' => { 'type' => 'string' } }
        }
      end
    end
  end
end
