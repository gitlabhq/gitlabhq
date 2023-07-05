# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SimilarityScore do
  let(:search) { '' }
  let(:query_result) { ActiveRecord::Base.connection.execute(query).to_a }

  let(:query) do
    # In memory query, with the id as the tie breaker.
    <<-SQL
      SELECT *, #{order_expression} AS similarity
        FROM (
          VALUES (1,   'Git',            'git',            'git source code mirror. this is a publish-only repository.'),
                 (2,   'GitLab Runner',  'gitlab-runner',  'official helm chart for the gitlab runner'),
                 (3,   'gitaly',         'gitaly',         'gitaly is a git rpc service for handling all the git calls made by gitlab'),
                 (4,   'GitLab',         'gitlab',         'gitlab is an open source end-to-end software development platform with built-in version control'),
                 (5,   'Gitlab Danger',  'gitlab-danger',  'this gem provides common dangerfile and plugins for gitlab projects'),
                 (6,   'different',      'same',           'same'),
                 (7,   'same',           'different',      'same'),
                 (8,   'gitlab-styles',  'gitlab-styles',  'gitlab style guides and shared style configs.'),
                 (9,   '🔒 gitaly',      'gitaly-sec',     'security mirror for gitaly')
        ) tbl    (id,  name,             path,             descrption) ORDER BY #{order_expression} DESC, id DESC;
    SQL
  end

  let(:order_expression) do
    described_class.build_expression(search: search, rules: [{ column: Arel.sql('path') }]).to_sql
  end

  subject { query_result.take(3).map { |row| row['path'] } }

  context 'when passing empty values' do
    context 'when search is nil' do
      let(:search) { nil }

      it 'orders by a constant 0 value' do
        expect(query).to include('ORDER BY CAST(0 AS integer) DESC')
      end
    end

    context 'when rules are empty' do
      let(:search) { 'text' }

      let(:order_expression) do
        described_class.build_expression(search: search, rules: []).to_sql
      end

      it 'orders by a constant 0 value' do
        expect(query).to include('ORDER BY CAST(0 AS integer) DESC')
      end
    end
  end

  context 'when similarity scoring based on the path' do
    let(:search) { 'git' }

    context 'when searching for `git`' do
      let(:search) { 'git' }

      it { expect(subject).to eq(%w[git gitlab gitaly]) }
    end

    context 'when searching for `gitlab`' do
      let(:search) { 'gitlab' }

      it { expect(subject).to eq(%w[gitlab gitlab-styles gitlab-danger]) }
    end

    context 'when searching for something unrelated' do
      let(:search) { 'xyz' }

      it 'results have 0 similarity score' do
        expect(query_result.map { |row| row['similarity'].to_f }).to all(eq(0))
      end
    end
  end

  describe 'score multiplier' do
    let(:order_expression) do
      described_class.build_expression(search: search, rules:
        [
          { column: Arel.sql('path'), multiplier: 1 },
          { column: Arel.sql('name'), multiplier: 0.8 }
        ]).to_sql
    end

    let(:search) { 'different' }

    it 'ranks `path` matches higher' do
      expect(subject).to eq(%w[different same gitlab-danger])
    end
  end

  describe 'annotation' do
    it 'annotates the generated SQL expression' do
      expression = described_class.build_expression(search: 'test', rules:
        [
          { column: Arel.sql('path'), multiplier: 1 },
          { column: Arel.sql('name'), multiplier: 0.8 }
        ])

      expect(described_class).to be_order_by_similarity(expression)
    end
  end
end
