# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Search::Params, feature_category: :global_search do
  subject(:search_params) { described_class.new(params, detect_abuse: detect_abuse) }

  let(:search) { 'search' }
  let(:group_id) { 123 }
  let(:params) { ActionController::Parameters.new(group_id: 123, search: search) }
  let(:detect_abuse) { true }

  describe 'detect_abuse conditional' do
    it 'does not call AbuseDetection' do
      expect(Gitlab::Search::AbuseDetection).not_to receive(:new)
      described_class.new(params, detect_abuse: false)
    end

    it 'uses AbuseDetection by default' do
      expect(Gitlab::Search::AbuseDetection).to receive(:new).at_least(:once).and_call_original

      search_params
    end
  end

  describe '#[]' do
    it 'feels like regular params' do
      expect(search_params[:group_id]).to eq(params[:group_id])
    end

    it 'has indifferent access' do
      params = described_class.new({ 'search' => search, group_id: group_id })
      expect(params['group_id']).to eq(group_id)
      expect(params[:search]).to eq(search)
    end

    it 'also works on attr_reader attributes' do
      expect(search_params[:query_string]).to eq(search_params.query_string)
    end
  end

  describe '#query_string' do
    let(:term) { 'term' }

    it "uses 'search' parameter" do
      params = described_class.new({ search: search })
      expect(params.query_string).to eq(search)
    end

    it "uses 'term' parameter" do
      params = described_class.new({ term: term })
      expect(params.query_string).to eq(term)
    end

    it "prioritizes 'search' over 'term'" do
      params = described_class.new({ search: search, term: term })
      expect(params.query_string).to eq(search)
    end

    it 'strips surrounding whitespace from query string' do
      params = described_class.new({ search: "     #{search}           " })
      expect(params.query_string).to eq(search)
    end
  end

  describe '#validate' do
    context 'when detect_abuse is disabled' do
      let(:detect_abuse) { false }

      it 'does NOT validate AbuseDetector' do
        expect(Gitlab::Search::AbuseDetection).not_to receive(:new)
        search_params.validate
      end
    end

    it 'validates AbuseDetector on validation' do
      expect(Gitlab::Search::AbuseDetection).to receive(:new).at_least(:once).and_call_original
      search_params.validate
    end

    context 'when query has too many terms' do
      let(:search) { Array.new((::Gitlab::Search::Params::SEARCH_TERM_LIMIT + 1), 'a').join(' ') }

      it { is_expected.not_to be_valid }
    end

    context 'when query is too long' do
      let(:search) { 'a' * (::Gitlab::Search::Params::SEARCH_CHAR_LIMIT + 1) }

      it { is_expected.not_to be_valid }
    end
  end

  describe '#valid?' do
    context 'when detect_abuse is disabled' do
      let(:detect_abuse) { false }

      it 'does NOT validate AbuseDetector' do
        expect(Gitlab::Search::AbuseDetection).not_to receive(:new)
        search_params.valid?
      end
    end

    it 'validates AbuseDetector on validation' do
      expect(Gitlab::Search::AbuseDetection).to receive(:new).at_least(:once).and_call_original
      search_params.valid?
    end
  end

  describe 'abuse detection' do
    let(:abuse_detection) { instance_double(Gitlab::Search::AbuseDetection) }

    before do
      allow(search_params).to receive(:abuse_detection).and_return abuse_detection
      allow(abuse_detection).to receive(:errors).and_return abuse_errors
    end

    context 'when there are abuse validation errors' do
      let(:abuse_errors) { { foo: ['bar'] } }

      it 'is considered abusive' do
        expect(search_params).to be_abusive
      end
    end

    context 'when there are NOT any abuse validation errors' do
      let(:abuse_errors) { {} }

      context 'and there are other validation errors' do
        it 'is NOT considered abusive' do
          allow(search_params).to receive(:valid?) do
            search_params.errors.add :project_id, 'validation error unrelated to abuse'
            false
          end

          expect(search_params).not_to be_abusive
        end
      end

      context 'and there are NO other validation errors' do
        it 'is NOT considered abusive' do
          allow(search_params).to receive(:valid?).and_return(true)

          expect(search_params).not_to be_abusive
        end
      end
    end
  end

  describe '#email_lookup?' do
    it 'is true if at least 1 word in search is an email' do
      expect(described_class.new({ search: 'email@example.com' })).to be_email_lookup
      expect(described_class.new({ search: 'foo email@example.com bar' })).to be_email_lookup
      expect(described_class.new({ search: 'foo bar' })).not_to be_email_lookup
    end
  end

  describe 'converts boolean params' do
    using RSpec::Parameterized::TableSyntax

    shared_context 'with inputs' do
      where(:input, :expected) do
        '0'     | false
        '1'     | true
        'yes'   | true
        'no'    | false
        'true'  | true
        'false' | false
        true    | true
        false   | false
      end
    end

    describe 'for confidential' do
      let(:params) { ActionController::Parameters.new(group_id: 123, search: search, confidential: input) }

      include_context 'with inputs'

      with_them do
        it 'transforms param' do
          expect(search_params[:confidential]).to eq(expected)
        end
      end
    end

    describe 'for include_archived' do
      let(:params) { ActionController::Parameters.new(group_id: 123, search: search, include_archived: input) }

      include_context 'with inputs'

      with_them do
        it 'transforms param' do
          expect(search_params[:include_archived]).to eq(expected)
        end
      end
    end

    describe 'for include_forked' do
      let(:params) { ActionController::Parameters.new(group_id: 123, search: search, include_forked: input) }

      include_context 'with inputs'

      with_them do
        it 'transforms param' do
          expect(search_params[:include_forked]).to eq(expected)
        end
      end
    end
  end

  describe 'converts not params' do
    using RSpec::Parameterized::TableSyntax

    where(:input, :expected_key, :expected_value) do
      { not: { source_branch: 'good-bye' } }              | 'not_source_branch' | 'good-bye'
      { not: { label_name: %w[hello-world labelName] } }  | 'not_label_name'    | %w[hello-world labelName]
      { label_name: %w[hello-world labelName] }           | 'label_name'        | %w[hello-world labelName]
      { source_branch: 'foo-bar' }                        | 'source_branch'     | 'foo-bar'
    end

    let(:params) { ActionController::Parameters.new(group_id: 123, search: search, **input) }

    with_them do
      it 'transforms param' do
        expect(search_params[expected_key]).to eq(expected_value)
      end
    end

    context 'when not param is not a hash' do
      let(:params) { ActionController::Parameters.new(group_id: 123, search: search, not: 'test') }

      it 'ignores the not param and removes it from params' do
        expect(search_params['not']).to be_nil
      end
    end
  end
end
