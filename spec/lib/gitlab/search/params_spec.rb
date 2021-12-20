# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Search::Params do
  subject { described_class.new(params, detect_abuse: detect_abuse) }

  let(:search) { 'search' }
  let(:group_id) { 123 }
  let(:params) { { group_id: 123, search: search } }
  let(:detect_abuse) { true }

  describe 'detect_abuse conditional' do
    it 'does not call AbuseDetection' do
      expect(Gitlab::Search::AbuseDetection).not_to receive(:new)
      described_class.new(params, detect_abuse: false)
    end

    it 'uses AbuseDetection by default' do
      expect(Gitlab::Search::AbuseDetection).to receive(:new).and_call_original
      described_class.new(params)
    end
  end

  describe '#[]' do
    it 'feels like regular params' do
      expect(subject[:group_id]).to eq(params[:group_id])
    end

    it 'has indifferent access' do
      params = described_class.new({ 'search' => search, group_id: group_id })
      expect(params['group_id']).to eq(group_id)
      expect(params[:search]).to eq(search)
    end

    it 'also works on attr_reader attributes' do
      expect(subject[:query_string]).to eq(subject.query_string)
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
      params = described_class.new({ search: '     ' + search + '           ' })
      expect(params.query_string).to eq(search)
    end
  end

  describe '#validate' do
    context 'when detect_abuse is disabled' do
      let(:detect_abuse) { false }

      it 'does NOT validate AbuseDetector' do
        expect(Gitlab::Search::AbuseDetection).not_to receive(:new)
        subject.validate
      end
    end

    it 'validates AbuseDetector on validation' do
      expect(Gitlab::Search::AbuseDetection).to receive(:new).and_call_original
      subject.validate
    end
  end

  describe '#valid?' do
    context 'when detect_abuse is disabled' do
      let(:detect_abuse) { false }

      it 'does NOT validate AbuseDetector' do
        expect(Gitlab::Search::AbuseDetection).not_to receive(:new)
        subject.valid?
      end
    end

    it 'validates AbuseDetector on validation' do
      expect(Gitlab::Search::AbuseDetection).to receive(:new).and_call_original
      subject.valid?
    end
  end

  describe 'abuse detection' do
    let(:abuse_detection) { instance_double(Gitlab::Search::AbuseDetection) }

    before do
      allow(subject).to receive(:abuse_detection).and_return abuse_detection
      allow(abuse_detection).to receive(:errors).and_return abuse_errors
    end

    context 'when there are abuse validation errors' do
      let(:abuse_errors) { { foo: ['bar'] } }

      it 'is considered abusive' do
        expect(subject).to be_abusive
      end
    end

    context 'when there are NOT any abuse validation errors' do
      let(:abuse_errors) { {} }

      context 'and there are other validation errors' do
        it 'is NOT considered abusive' do
          allow(subject).to receive(:valid?) do
            subject.errors.add :project_id, 'validation error unrelated to abuse'
            false
          end

          expect(subject).not_to be_abusive
        end
      end

      context 'and there are NO other validation errors' do
        it 'is NOT considered abusive' do
          allow(subject).to receive(:valid?).and_return(true)

          expect(subject).not_to be_abusive
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
end
