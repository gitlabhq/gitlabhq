# frozen_string_literal: true

module Atlassian
  module Schemata
    def self.build_info
      {
        'type' => 'object',
        'required' => %w(schemaVersion pipelineId buildNumber updateSequenceNumber displayName url state issueKeys testInfo references),
        'properties' => {
          'schemaVersion' => { 'type' => 'string', 'pattern' => '1.0' },
          'pipelineId' => { 'type' => 'string' },
          'buildNumber' => { 'type' => 'integer' },
          'updateSequenceNumber' => { 'type' => 'integer' },
          'displayName' => { 'type' => 'string' },
          'url' => { 'type' => 'string' },
          'state' => {
            'type' => 'string',
            'pattern' => '(pending|in_progress|successful|failed|cancelled)'
          },
          'issueKeys' => {
            'type' => 'array',
            'items' => { 'type' => 'string' },
            'minItems' => 1
          },
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

    def self.build_info_payload
      {
        'type' => 'object',
        'required' => %w(providerMetadata builds),
        'properties' => {
          'providerMetadata' => provider_metadata,
          'builds' => { 'type' => 'array', 'items' => build_info }
        }
      }
    end

    def self.provider_metadata
      {
        'type' => 'object',
        'required' => %w(product),
        'properties' => { 'product' => { 'type' => 'string' } }
      }
    end
  end
end
