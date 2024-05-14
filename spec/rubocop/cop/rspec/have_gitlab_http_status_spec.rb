# frozen_string_literal: true

require 'rubocop_spec_helper'

require 'rspec-parameterized'
require_relative '../../../../rubocop/cop/rspec/have_gitlab_http_status'

RSpec.describe RuboCop::Cop::RSpec::HaveGitlabHttpStatus, feature_category: :tooling do
  using RSpec::Parameterized::TableSyntax

  let(:source_file) { 'spec/foo_spec.rb' }

  shared_examples 'offense' do |bad, good|
    it 'registers an offense', :aggregate_failures do
      expect_offense(<<~CODE, node: bad)
        %{node}
        ^{node} [...]
      CODE

      expect_correction(<<~CODE)
        #{good}
      CODE
    end
  end

  shared_examples 'no offense' do |code|
    it 'does not register an offense' do
      expect_no_offenses(code)
    end
  end

  shared_examples 'offense with no autocorrect' do |code|
    it 'does not autocorrect' do
      expect_offense(<<~CODE, node: code)
        %{node}
        ^{node} [...]
      CODE

      expect_no_corrections
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
      include_examples 'offense', params[:bad], params[:good]
      include_examples 'no offense', params[:good]
    end
  end

  describe 'partially autocorrects invalid numeric status' do
    where(:bad, :good) do
      'have_http_status(-1)' | 'have_gitlab_http_status(-1)'
    end

    with_them do
      include_examples 'offense', params[:bad], params[:good]
      include_examples 'offense with no autocorrect', params[:good]
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
    end
  end
end
