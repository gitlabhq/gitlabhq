# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Search::AbuseDetection, feature_category: :global_search do
  subject { described_class.new(params) }

  let(:params) { { query_string: 'foobar' } }

  describe 'abusive scopes validation' do
    it 'allows only approved scopes' do
      described_class::ALLOWED_SCOPES.each do |scope|
        expect(described_class.new({ scope: scope })).to be_valid
      end
    end

    it 'disallows anything not approved' do
      expect(described_class.new({ scope: 'nope' })).not_to be_valid
    end
  end

  describe 'abusive character matching' do
    refs = %w[
      main
      тест
      maiñ
      main123
      main-v123
      main-v12.3
      feature/it_works
      really_important!
      测试
      main+testing
    ]

    refs.each do |ref|
      it "does match refs permitted by git refname: #{ref}" do
        [:repository_ref, :project_ref].each do |param|
          validation = described_class.new(Hash[param, ref])
          expect(validation).to be_valid
        end
      end

      it "does NOT match refs with special characters: #{ref}" do
        ['?', '\\', ' '].each do |special_character|
          [:repository_ref, :project_ref].each do |param|
            validation = described_class.new(Hash[param, ref + special_character])
            expect(validation).not_to be_valid
          end
        end
      end
    end
  end

  describe 'numericality validation' do
    it 'considers non Integers to be invalid' do
      [:project_id, :group_id].each do |param|
        [[1, 2, 3], 'xyz', 3.14, { foo: :bar }].each do |dtype|
          expect(described_class.new({ param => dtype })).not_to be_valid
        end
      end
    end

    it 'considers Integers to be valid' do
      [:project_id, :group_id].each do |param|
        expect(described_class.new({ param => 123 })).to be_valid
      end
    end
  end

  describe 'query_string validation' do
    using ::RSpec::Parameterized::TableSyntax

    subject { described_class.new({ query_string: search }) }

    let(:validation_errors) do
      subject.validate
      subject.errors.messages
    end

    where(:search, :errors) do
      described_class::STOP_WORDS.each do |word|
        word | { query_string: ['stopword only abusive search detected'] }
      end

      (['apples'] * (described_class::MAX_PIPE_SYNTAX_FILTERS + 1)).join('|') | { query_string: ['too many pipe syntax filters'] }
      (['apples'] * described_class::MAX_PIPE_SYNTAX_FILTERS).join('|')       | {}
      'x'                                                   | { query_string: ['abusive tiny search detected'] }
      'apples|x'                                            | { query_string: ['abusive tiny search detected'] }
      ('x' * described_class::ABUSIVE_TERM_SIZE)            | { query_string: ['abusive term length detected'] }
      "apples|#{'x' * described_class::ABUSIVE_TERM_SIZE}"  | { query_string: ['abusive term length detected'] }
      ''                                                    | {}
      '*'                                                   | {}
      'ruby'                                                | {}
    end

    with_them do
      it 'validates query string for pointless search' do
        expect(validation_errors).to eq(errors)
      end
    end
  end

  describe 'abusive type coercion from string validation' do
    it 'considers anything not a String invalid' do
      [:query_string, :scope, :repository_ref, :project_ref].each do |param|
        [[1, 2, 3], 123, 3.14, { foo: :bar }].each do |dtype|
          expect(described_class.new({ param => dtype })).not_to be_valid
        end
      end
    end

    it 'considers Strings to be valid' do
      [:query_string, :repository_ref, :project_ref].each do |param|
        expect(described_class.new({ param => "foo" })).to be_valid
      end
    end
  end
end
