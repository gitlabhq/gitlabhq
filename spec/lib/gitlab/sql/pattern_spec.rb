# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SQL::Pattern, feature_category: :shared do
  using RSpec::Parameterized::TableSyntax

  describe '.fuzzy_search' do
    let_it_be(:issue1) { create(:issue, title: 'noise foo noise', description: 'noise bar noise') }
    let_it_be(:issue2) { create(:issue, title: 'noise baz noise', description: 'noise foo noise') }
    let_it_be(:issue3) { create(:issue, title: 'Oh', description: 'Ah') }
    let_it_be(:issue4) { create(:issue, title: 'beep beep', description: 'beep beep') }
    let_it_be(:issue5) { create(:issue, title: 'beep', description: 'beep') }

    subject(:fuzzy_search) { Issue.fuzzy_search(query, columns, exact_matches_first: exact_matches_first) }

    where(:query, :columns, :exact_matches_first, :expected) do
      'foo' | [Issue.arel_table[:title]] | false | %i[issue1]

      'foo' | %i[title]             | false | %i[issue1]
      'foo' | %w[title]             | false | %i[issue1]
      'foo' | %i[description]       | false | %i[issue2]
      'foo' | %i[title description] | false | %i[issue1 issue2]
      'bar' | %i[title description] | false | %i[issue1]
      'baz' | %i[title description] | false | %i[issue2]
      'qux' | %i[title description] | false | []

      'oh' | %i[title description] | false | %i[issue3]
      'OH' | %i[title description] | false | %i[issue3]
      'ah' | %i[title description] | false | %i[issue3]
      'AH' | %i[title description] | false | %i[issue3]
      'oh' | %i[title]             | false | %i[issue3]
      'ah' | %i[description]       | false | %i[issue3]

      ''      | %i[title]          | false | %i[issue1 issue2 issue3 issue4 issue5]
      %w[a b] | %i[title]          | false | %i[issue1 issue2 issue3 issue4 issue5]

      'beep'  | %i[title]          | true  | %i[issue5 issue4]
    end

    with_them do
      let(:expected_issues) { expected.map { |sym| send(sym) } }

      it 'finds the expected issues' do
        if exact_matches_first
          expect(fuzzy_search).to eq(expected_issues)
        else
          expect(fuzzy_search).to match_array(expected_issues)
        end
      end
    end
  end

  describe '.to_pattern' do
    subject(:to_pattern) { User.to_pattern(query) }

    context 'when a query is shorter than 3 chars' do
      let(:query) { '12' }

      it 'returns exact matching pattern' do
        expect(to_pattern).to eq('12')
      end

      context 'and ignore_minimum_char_limit is true' do
        it 'returns partial matching pattern' do
          expect(User.to_pattern(query, use_minimum_char_limit:  false)).to eq('%12%')
        end
      end
    end

    context 'when a query with a escape character is shorter than 3 chars' do
      let(:query) { '_2' }

      it 'returns sanitized exact matching pattern' do
        expect(to_pattern).to eq('\_2')
      end

      context 'and ignore_minimum_char_limit is true' do
        it 'returns sanitized partial matching pattern' do
          expect(User.to_pattern(query, use_minimum_char_limit:  false)).to eq('%\_2%')
        end
      end
    end

    context 'when a query is equal to 3 chars' do
      let(:query) { '123' }

      it 'returns partial matching pattern' do
        expect(to_pattern).to eq('%123%')
      end
    end

    context 'when a query with a escape character is equal to 3 chars' do
      let(:query) { '_23' }

      it 'returns partial matching pattern' do
        expect(to_pattern).to eq('%\_23%')
      end
    end

    context 'when a query is longer than 3 chars' do
      let(:query) { '1234' }

      it 'returns partial matching pattern' do
        expect(to_pattern).to eq('%1234%')
      end
    end

    context 'when a query with a escape character is longer than 3 chars' do
      let(:query) { '_234' }

      it 'returns sanitized partial matching pattern' do
        expect(to_pattern).to eq('%\_234%')
      end
    end
  end

  describe '.select_fuzzy_terms' do
    subject(:select_fuzzy_terms) { Issue.select_fuzzy_terms(query) }

    context 'with a word equal to 3 chars' do
      let(:query) { 'foo' }

      it 'returns array containing a word' do
        expect(select_fuzzy_terms).to match_array(['foo'])
      end
    end

    context 'with a word shorter than 3 chars' do
      let(:query) { 'fo' }

      it 'returns empty array' do
        expect(select_fuzzy_terms).to be_empty
      end
    end

    context 'with two words both equal to 3 chars' do
      let(:query) { 'foo baz' }

      it 'returns array containing two words' do
        expect(select_fuzzy_terms).to match_array(%w[foo baz])
      end
    end

    context 'with two words divided by two spaces both equal to 3 chars' do
      let(:query) { 'foo  baz' }

      it 'returns array containing two words' do
        expect(select_fuzzy_terms).to match_array(%w[foo baz])
      end
    end

    context 'with two words equal to 3 chars and shorter than 3 chars' do
      let(:query) { 'foo ba' }

      it 'returns array containing a word' do
        expect(select_fuzzy_terms).to match_array(['foo'])
      end
    end
  end

  describe '.split_query_to_search_terms' do
    subject(:split_query_to_search_terms) { described_class.split_query_to_search_terms(query) }

    context 'with words separated by spaces' do
      let(:query) { 'really bar  baz' }

      it 'returns array containing individual words' do
        expect(split_query_to_search_terms).to match_array(%w[really bar baz])
      end
    end

    context 'with a multi-word surrounded by double quote' do
      let(:query) { '"really bar"' }

      it 'returns array containing a multi-word' do
        expect(split_query_to_search_terms).to match_array(['really bar'])
      end
    end

    context 'with a multi-word surrounded by double quote and two words' do
      let(:query) { 'foo "really bar" baz' }

      it 'returns array containing a multi-word and two words' do
        expect(split_query_to_search_terms).to match_array(['foo', 'really bar', 'baz'])
      end
    end

    context 'with a multi-word surrounded by double quote missing a spece before the first double quote' do
      let(:query) { 'foo"really bar"' }

      it 'returns array containing two words with double quote' do
        expect(split_query_to_search_terms).to match_array(['foo"really', 'bar"'])
      end
    end

    context 'with a multi-word surrounded by double quote missing a spece after the second double quote' do
      let(:query) { '"really bar"baz' }

      it 'returns array containing two words with double quote' do
        expect(split_query_to_search_terms).to match_array(['"really', 'bar"baz'])
      end
    end

    context 'with two multi-word surrounded by double quote and two words' do
      let(:query) { 'foo "really bar" baz "awesome feature"' }

      it 'returns array containing two multi-words and two words' do
        expect(split_query_to_search_terms).to match_array(['foo', 'really bar', 'baz', 'awesome feature'])
      end
    end
  end

  describe '.fuzzy_arel_match' do
    subject(:fuzzy_arel_match) { Issue.fuzzy_arel_match(:title, query) }

    context 'with a word equal to 3 chars' do
      let(:query) { 'foo' }

      it 'returns a single ILIKE condition' do
        expect(fuzzy_arel_match.to_sql).to match(/title.*I?LIKE '%foo%'/)
      end
    end

    context 'with a word shorter than 3 chars' do
      let(:query) { 'fo' }

      it 'returns a single equality condition' do
        expect(fuzzy_arel_match.to_sql).to match(/title.*I?LIKE 'fo'/)
      end

      it 'uses LOWER instead of ILIKE when LOWER is enabled' do
        rel = Issue.fuzzy_arel_match(:title, query, lower_exact_match: true)

        expect(rel.to_sql).to match(/LOWER\(.*title.*\).*=.*'fo'/)
      end
    end

    context 'with two words both equal to 3 chars' do
      let(:query) { 'foo baz' }

      it 'returns a joining LIKE condition using a AND' do
        expect(fuzzy_arel_match.to_sql).to match(/title.+I?LIKE '%foo%' AND .*title.*I?LIKE '%baz%'/)
      end
    end

    context 'with two words both shorter than 3 chars' do
      let(:query) { 'fo ba' }

      it 'returns a single ILIKE condition' do
        expect(fuzzy_arel_match.to_sql).to match(/title.*I?LIKE 'fo ba'/)
      end
    end

    context 'with two words, one shorter 3 chars' do
      let(:query) { 'foo ba' }

      it 'returns a single ILIKE condition using the longer word' do
        expect(fuzzy_arel_match.to_sql).to match(/title.+I?LIKE '%foo%'/)
      end
    end

    context 'with a multi-word surrounded by double quote and two words' do
      let(:query) { 'foo "really bar" baz' }

      it 'returns a joining LIKE condition using a AND' do
        expect(fuzzy_arel_match.to_sql).to match(/title.+I?LIKE '%foo%' AND .*title.*I?LIKE '%baz%' AND .*title.*I?LIKE '%really bar%'/)
      end
    end

    context 'when passing an Arel column' do
      let(:query) { 'foo' }

      subject(:fuzzy_arel_match) { Project.fuzzy_arel_match(Route.arel_table[:path], query) }

      it 'returns a condition with the table and column name' do
        expect(fuzzy_arel_match.to_sql).to match(/"routes"."path".*ILIKE '%foo%'/)
      end
    end
  end
end
