# frozen_string_literal: true

require 'fast_spec_helper'

require 'rspec-parameterized'
require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/rspec/have_gitlab_http_status'

RSpec.describe RuboCop::Cop::RSpec::HaveGitlabHttpStatus do
  include CopHelper

  using RSpec::Parameterized::TableSyntax

  let(:source_file) { 'spec/foo_spec.rb' }

  subject(:cop) { described_class.new }

  shared_examples 'offense' do |code|
    it 'registers an offense' do
      inspect_source(code, source_file)

      expect(cop.offenses.size).to eq(1)
      expect(cop.offenses.map(&:line)).to eq([1])
      expect(cop.highlights).to eq([code])
    end
  end

  shared_examples 'no offense' do |code|
    it 'does not register an offense' do
      inspect_source(code)

      expect(cop.offenses).to be_empty
    end
  end

  shared_examples 'autocorrect' do |bad, good|
    it 'autocorrects' do
      autocorrected = autocorrect_source(bad, source_file)

      expect(autocorrected).to eql(good)
    end
  end

  shared_examples 'no autocorrect' do |code|
    it 'does not autocorrect' do
      autocorrected = autocorrect_source(code, source_file)

      expect(autocorrected).to eql(code)
    end
  end

  describe 'offenses and autocorrections' do
    where(:bad, :good) do
      'have_http_status(:ok)'        | 'have_gitlab_http_status(:ok)'
      'have_http_status(204)'        | 'have_gitlab_http_status(:no_content)'
      'have_gitlab_http_status(201)' | 'have_gitlab_http_status(:created)'
      'have_http_status(var)'        | 'have_gitlab_http_status(var)'
      'have_http_status(:success)'   | 'have_gitlab_http_status(:success)'
      'have_http_status(:invalid)'   | 'have_gitlab_http_status(:invalid)'
      'expect(response.status).to eq(200)'     | 'expect(response).to have_gitlab_http_status(:ok)'
      'expect(response.status).not_to eq(200)' | 'expect(response).not_to have_gitlab_http_status(:ok)'
    end

    with_them do
      include_examples 'offense', params[:bad]
      include_examples 'no offense', params[:good]
      include_examples 'autocorrect', params[:bad], params[:good]
      include_examples 'no autocorrect', params[:good]
    end
  end

  describe 'partially autocorrects invalid numeric status' do
    where(:bad, :good) do
      'have_http_status(-1)' | 'have_gitlab_http_status(-1)'
    end

    with_them do
      include_examples 'offense', params[:bad]
      include_examples 'offense', params[:good]
      include_examples 'autocorrect', params[:bad], params[:good]
      include_examples 'no autocorrect', params[:good]
    end
  end

  describe 'ignore' do
    where(:code) do
      [
        'have_http_status',
        'have_http_status { }',
        'have_http_status(200, arg)',
        'have_gitlab_http_status',
        'have_gitlab_http_status { }',
        'have_gitlab_http_status(200, arg)',
        'expect(response.status).to eq(arg)',
        'expect(response.status).to eq(:ok)',
        'expect(response.status).to some_matcher(200)',
        'expect(response.status).not_to eq(arg)',
        'expect(response.status).not_to eq(:ok)',
        'expect(response.status).not_to some_matcher(200)',
        'expect(result.status).to eq(200)',
        'expect(result.status).not_to eq(200)',
        <<~CODE,
          response = some_assignment
          expect(response.status).to eq(200)
        CODE
        <<~CODE
          response = some_assignment
          expect(response.status).not_to eq(200)
        CODE
      ]
    end

    with_them do
      include_examples 'no offense', params[:code]
      include_examples 'no autocorrect', params[:code]
    end
  end
end
