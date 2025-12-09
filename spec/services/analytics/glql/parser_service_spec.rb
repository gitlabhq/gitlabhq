# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::Glql::ParserService, feature_category: :custom_dashboards_foundation do
  describe '#execute' do
    subject(:execute) { described_class.new(glql_yaml: glql_yaml).execute }

    context 'with frontmatter format' do
      where(:description, :input, :expected_query, :expected_config) do
        [
          [
            'complete configuration',
            <<~YAML.chomp,
              ---
              fields: id,title,state
              limit: 50
              sort: created_at
              group: my-group
              ---
              type = issue and state = opened
            YAML
            'type = issue and state = opened',
            { 'fields' => 'id,title,state', 'limit' => 50, 'sort' => 'created_at', 'group' => 'my-group' }
          ],
          [
            'project scope',
            <<~YAML.chomp,
              ---
              fields: title
              project: my-group/my-project
              ---
              type = issue
            YAML
            'type = issue',
            { 'fields' => 'title', 'project' => 'my-group/my-project' }
          ],
          [
            'whitespace in config',
            "---\n\nfields: title\n\n---\ntype = issue",
            'type = issue',
            { 'fields' => 'title' }
          ],
          [
            'multiline query',
            <<~YAML.chomp,
              ---
              fields: title
              ---
              type = issue and
              state = opened and
              assignee = @me
            YAML
            "type = issue and\nstate = opened and\nassignee = @me",
            { 'fields' => 'title' }
          ],
          [
            'all configuration options',
            <<~YAML.chomp,
              ---
              fields: id,title,state,assignee
              limit: 75
              sort: created_at
              group: my-group
              project: my-group/my-project
              ---
              type = issue and state = opened
            YAML
            'type = issue and state = opened',
            { 'fields' => 'id,title,state,assignee', 'limit' => 75, 'sort' => 'created_at', 'group' => 'my-group',
              'project' => 'my-group/my-project' }
          ]
        ]
      end

      with_them do
        let(:glql_yaml) { input }

        it 'parses query and config correctly' do
          result = execute

          expect(result[:query]).to eq(expected_query)
          expect(result[:config]).to eq(expected_config)
        end
      end
    end

    context 'with pure YAML format' do
      where(:description, :input, :expected_query, :expected_config) do
        [
          [
            'query key and config',
            "query: type = issue and state = opened\nfields: id,title,state\nlimit: 25\nsort: updated_at",
            'type = issue and state = opened',
            { 'fields' => 'id,title,state', 'limit' => 25, 'sort' => 'updated_at' }
          ],
          [
            'only query key',
            "query: type = issue",
            'type = issue',
            {}
          ],
          [
            'group scope',
            "query: type = issue\ngroup: my-group/subgroup\nfields: title,state",
            'type = issue',
            { 'group' => 'my-group/subgroup', 'fields' => 'title,state' }
          ],
          [
            'numeric and boolean values',
            "query: type = issue\nlimit: 100\nsome_flag: true\nanother_value: 42",
            'type = issue',
            { 'limit' => 100, 'some_flag' => true, 'another_value' => 42 }
          ]
        ]
      end

      with_them do
        let(:glql_yaml) { input }

        it 'parses query and config correctly' do
          result = execute

          expect(result[:query]).to eq(expected_query)
          expect(result[:config]).to eq(expected_config)
        end
      end
    end

    context 'with plain query strings and invalid YAML' do
      where(:description, :input, :expected_query, :expected_config) do
        [
          ['simple query', 'type = issue and state = opened', 'type = issue and state = opened', {}],
          ['complex query', 'type = issue and (state = opened or state = closed) and assignee = @me',
            'type = issue and (state = opened or state = closed) and assignee = @me', {}],
          ['query with special characters', 'title contains "bug: fix" and state = opened',
            'title contains "bug: fix" and state = opened', {}],
          ['invalid YAML structure', 'type = issue: invalid: yaml: structure',
            'type = issue: invalid: yaml: structure', {}],
          ['malformed YAML', "query:\n  - invalid\n  - structure\ntype = issue",
            "query:\n  - invalid\n  - structure\ntype = issue", {}],
          ['hash without query key', "fields: title\nlimit: 10", "fields: title\nlimit: 10", {}],
          ['YAML array', "- item1\n- item2", "- item1\n- item2", {}],
          ['frontmatter with empty config', "---\n\n---\ntype = issue", "---\n\n---\ntype = issue", {}],
          ['empty string', '', '', {}],
          ['only whitespace', "   \n  \n   ", '', {}]
        ]
      end

      with_them do
        it 'treats as plain query or returns empty' do
          result = described_class.new(glql_yaml: input).execute

          expect(result[:query]).to eq(expected_query)
          expect(result[:config]).to eq(expected_config)
        end
      end
    end

    it 'falls back to standard YAML parsing when Psych::Exception is raised' do
      yaml = "---\nfields: title\ninvalid: value\n---\ntype = issue"
      allow(YAML).to receive(:safe_load).and_raise(Psych::Exception)

      result = described_class.new(glql_yaml: yaml).execute

      expect(result[:query]).to eq(yaml)
      expect(result[:config]).to eq({})
    end

    it 'raises ArgumentError when input exceeds limit' do
      expect { described_class.new(glql_yaml: 'a' * 10_001).execute }
        .to raise_error(ArgumentError, 'Input exceeds maximum size')
    end

    it 'accepts input at exactly the limit' do
      expect { described_class.new(glql_yaml: 'a' * 10_000).execute }.not_to raise_error
    end
  end
end
