# frozen_string_literal: true

module Atlassian
  module Schemata
    class << self
      def build_info
        {
          'type' => 'object',
          'additionalProperties' => false,
          'required' => %w[
            schemaVersion pipelineId buildNumber updateSequenceNumber
            displayName url state issueKeys testInfo references
            lastUpdated
          ],
          'properties' => {
            'schemaVersion' => schema_version_type,
            'pipelineId' => { 'type' => 'string' },
            'buildNumber' => { 'type' => 'integer' },
            'updateSequenceNumber' => { 'type' => 'integer' },
            'displayName' => { 'type' => 'string' },
            'lastUpdated' => iso8601_type,
            'url' => { 'type' => 'string' },
            'state' => state_type,
            'issueKeys' => issue_keys_type,
            'testInfo' => {
              'type' => 'object',
              'required' => %w[totalNumber numberPassed numberFailed numberSkipped],
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
                'required' => %w[commit ref],
                'properties' => {
                  'commit' => {
                    'type' => 'object',
                    'required' => %w[id repositoryUri],
                    'properties' => {
                      'id' => { 'type' => 'string' },
                      'repositoryUri' => { 'type' => 'string' }
                    }
                  },
                  'ref' => {
                    'type' => 'object',
                    'required' => %w[name uri],
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
          'required' => %w[
            deploymentSequenceNumber updateSequenceNumber
            associations displayName url description lastUpdated
            state pipeline environment
          ],
          'properties' => {
            'deploymentSequenceNumber' => { 'type' => 'integer' },
            'updateSequenceNumber' => { 'type' => 'integer' },
            'associations' => {
              'type' => %w[array],
              'items' => association_type,
              'minItems' => 1
            },
            'displayName' => { 'type' => 'string' },
            'description' => { 'type' => 'string' },
            'label' => { 'type' => 'string' },
            'url' => { 'type' => 'string' },
            'lastUpdated' => iso8601_type,
            'state' => state_type,
            'pipeline' => pipeline_type,
            'environment' => environment_type,
            'schemaVersion' => schema_version_type,
            'commands' => {
              'anyOf' => [
                {
                  'type' => %w[array],
                  'items' => command_type,
                  'minItems' => 1
                },
                { 'type' => 'null' }
              ]
            }
          }
        }
      end

      def feature_flag_info
        {
          'type' => 'object',
          'additionalProperties' => false,
          'required' => %w[
            updateSequenceId id key issueKeys summary details
          ],
          'properties' => {
            'id' => { 'type' => 'string' },
            'key' => { 'type' => 'string' },
            'displayName' => { 'type' => 'string' },
            'issueKeys' => issue_keys_type,
            'summary' => summary_type,
            'details' => details_type,
            'updateSequenceId' => { 'type' => 'integer' },
            'schemaVersion' => schema_version_type
          }
        }
      end

      def details_type
        {
          'type' => 'array',
          'items' => combine(summary_type, {
            'required' => ['environment'],
            'properties' => {
              'environment' => {
                'type' => 'object',
                'additionalProperties' => false,
                'required' => %w[name],
                'properties' => {
                  'name' => { 'type' => 'string' },
                  'type' => {
                    'type' => 'string',
                    'pattern' => '^(development|testing|staging|production)$'
                  }
                }
              }
            }
          })
        }
      end

      def combine(map_a, map_b)
        map_a.merge(map_b) do |k, a, b|
          a.respond_to?(:merge) ? a.merge(b) : a + b
        end
      end

      def summary_type
        {
          'type' => 'object',
          'additionalProperties' => false,
          'required' => %w[url status lastUpdated],
          'properties' => {
            'lastUpdated' => iso8601_type,
            'url' => { 'type' => 'string' },
            'status' => feature_status_type
          }
        }
      end

      def feature_status_type
        {
          'type' => 'object',
          'additionalProperties' => false,
          'required' => %w[enabled],
          'properties' => {
            'enabled' => { 'type' => 'boolean' },
            'defaultValue' => { 'type' => 'string' },
            'rollout' => rollout_type
          }
        }
      end

      def rollout_type
        {
          'type' => 'object',
          'additionalProperties' => false,
          'properties' => {
            'percentage' => { 'type' => 'number' },
            'text' => { 'type' => 'string' },
            'rules' => { 'type' => 'number' }
          }
        }
      end

      def environment_type
        {
          'type' => 'object',
          'additionalProperties' => false,
          'required' => %w[id displayName type],
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
          'required' => %w[id displayName url],
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
          'required' => %w[associationType values],
          'properties' => {
            'associationType' => {
              'type' => 'string',
              'pattern' => '(issueKeys|issueIdOrKeys|serviceIdOrKeys)'
            },
            'values' => issue_keys_type
          }
        }
      end

      def command_type
        {
          'type' => 'object',
          'additionalProperties' => false,
          'required' => %w[command],
          'properties' => {
            'command' => { 'type' => 'string' }
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

      def ff_info_payload
        pl = payload('flags', feature_flag_info)
        pl['properties']['properties'] = {
          'type' => 'object',
          'additionalProperties' => { 'type' => 'string' },
          'maxProperties' => 5,
          'propertyNames' => { 'pattern' => '^[^_][^:]+$' }
        }
        pl
      end

      def payload(key, schema)
        {
          'type' => 'object',
          'additionalProperties' => false,
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
          'required' => %w[product],
          'properties' => { 'product' => { 'type' => 'string' } }
        }
      end

      def iso8601_type
        {
          'type' => 'string',
          'pattern' => '^-?([1-9][0-9]*)?[0-9]{4}-(1[0-2]|0[1-9])-(3[01]|0[1-9]|[12][0-9])T(2[0-3]|[01][0-9]):([0-5][0-9]):([0-5][0-9])(\.[0-9]+)?(Z|[+-](?:2[0-3]|[01][0-9]):[0-5][0-9])?$'
        }
      end
    end
  end
end
