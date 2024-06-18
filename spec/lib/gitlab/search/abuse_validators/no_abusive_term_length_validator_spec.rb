# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Search::AbuseValidators::NoAbusiveTermLengthValidator do
  subject do
    described_class.new({ attributes: { foo: :bar }, maximum: limit, maximum_for_url: url_limit })
  end

  let(:limit) { 100 }
  let(:url_limit) { limit * 2 }
  let(:instance) { double(:instance) }
  let(:attribute) { :search }
  let(:validation_msg) { 'abusive term length detected' }
  let(:validate) { subject.validate_each(instance, attribute, search) }

  context 'when a term is over the limit' do
    let(:search) { "this search is too lo#{'n' * limit}g" }

    it 'adds a validation error' do
      expect(instance).to receive_message_chain(:errors, :add).with(attribute, validation_msg)
      validate
    end
  end

  context 'when all terms are under the limit' do
    let(:search) { "what is love? baby don't hurt me" }

    it 'does NOT add any validation errors' do
      expect(instance).not_to receive(:errors)
      validate
    end
  end

  context 'when a URL is detected in a search term' do
    let(:double_limit) { limit * 2 }
    let(:terms) do
      [
        'http://' + ('x' * (double_limit - 12)) + '.com',
        'https://' + ('x' * (double_limit - 13)) + '.com',
        'sftp://' + ('x' * (double_limit - 12)) + '.com',
        'ftp://' + ('x' * (double_limit - 11)) + '.com',
        'http://' + ('x' * (double_limit - 8)) # no tld is OK
      ]
    end

    context 'when under twice the limit' do
      let(:search) { terms.join(' ') }

      it 'does NOT add any validation errors' do
        search.split.each do |term|
          expect(term.length).to be < url_limit
        end

        expect(instance).not_to receive(:errors)
        validate
      end
    end

    context 'when over twice the limit' do
      let(:search) do
        terms.map { |t| t + 'xxxxxxxx' }.join(' ')
      end

      it 'adds a validation error' do
        expect(instance).to receive_message_chain(:errors, :add).with(attribute, validation_msg)
        validate
      end
    end
  end
end
