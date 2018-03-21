require 'spec_helper'

describe Gitlab::SQL::Pattern do
  describe '.to_pattern' do
    subject(:to_pattern) { User.to_pattern(query) }

    context 'when a query is shorter than 3 chars' do
      let(:query) { '12' }

      it 'returns exact matching pattern' do
        expect(to_pattern).to eq('12')
      end
    end

    context 'when a query with a escape character is shorter than 3 chars' do
      let(:query) { '_2' }

      it 'returns sanitized exact matching pattern' do
        expect(to_pattern).to eq('\_2')
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

  describe '.select_fuzzy_words' do
    subject(:select_fuzzy_words) { Issue.select_fuzzy_words(query) }

    context 'with a word equal to 3 chars' do
      let(:query) { 'foo' }

      it 'returns array cotaining a word' do
        expect(select_fuzzy_words).to match_array(['foo'])
      end
    end

    context 'with a word shorter than 3 chars' do
      let(:query) { 'fo' }

      it 'returns empty array' do
        expect(select_fuzzy_words).to match_array([])
      end
    end

    context 'with two words both equal to 3 chars' do
      let(:query) { 'foo baz' }

      it 'returns array containing two words' do
        expect(select_fuzzy_words).to match_array(%w[foo baz])
      end
    end

    context 'with two words divided by two spaces both equal to 3 chars' do
      let(:query) { 'foo  baz' }

      it 'returns array containing two words' do
        expect(select_fuzzy_words).to match_array(%w[foo baz])
      end
    end

    context 'with two words equal to 3 chars and shorter than 3 chars' do
      let(:query) { 'foo ba' }

      it 'returns array containing a word' do
        expect(select_fuzzy_words).to match_array(['foo'])
      end
    end

    context 'with a multi-word surrounded by double quote' do
      let(:query) { '"really bar"' }

      it 'returns array containing a multi-word' do
        expect(select_fuzzy_words).to match_array(['really bar'])
      end
    end

    context 'with a multi-word surrounded by double quote and two words' do
      let(:query) { 'foo "really bar" baz' }

      it 'returns array containing a multi-word and tow words' do
        expect(select_fuzzy_words).to match_array(['foo', 'really bar', 'baz'])
      end
    end

    context 'with a multi-word surrounded by double quote missing a spece before the first double quote' do
      let(:query) { 'foo"really bar"' }

      it 'returns array containing two words with double quote' do
        expect(select_fuzzy_words).to match_array(['foo"really', 'bar"'])
      end
    end

    context 'with a multi-word surrounded by double quote missing a spece after the second double quote' do
      let(:query) { '"really bar"baz' }

      it 'returns array containing two words with double quote' do
        expect(select_fuzzy_words).to match_array(['"really', 'bar"baz'])
      end
    end

    context 'with two multi-word surrounded by double quote and two words' do
      let(:query) { 'foo "really bar" baz "awesome feature"' }

      it 'returns array containing two multi-words and tow words' do
        expect(select_fuzzy_words).to match_array(['foo', 'really bar', 'baz', 'awesome feature'])
      end
    end
  end

  describe '.fuzzy_arel_match' do
    subject(:fuzzy_arel_match) { Issue.fuzzy_arel_match(:title, query) }

    context 'with a word equal to 3 chars' do
      let(:query) { 'foo' }

      it 'returns a single ILIKE condition' do
        expect(fuzzy_arel_match.to_sql).to match(/title.*I?LIKE '\%foo\%'/)
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
        expect(fuzzy_arel_match.to_sql).to match(/title.+I?LIKE '\%foo\%' AND .*title.*I?LIKE '\%baz\%'/)
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
        expect(fuzzy_arel_match.to_sql).to match(/title.+I?LIKE '\%foo\%'/)
      end
    end

    context 'with a multi-word surrounded by double quote and two words' do
      let(:query) { 'foo "really bar" baz' }

      it 'returns a joining LIKE condition using a AND' do
        expect(fuzzy_arel_match.to_sql).to match(/title.+I?LIKE '\%foo\%' AND .*title.*I?LIKE '\%baz\%' AND .*title.*I?LIKE '\%really bar\%'/)
      end
    end
  end
end
