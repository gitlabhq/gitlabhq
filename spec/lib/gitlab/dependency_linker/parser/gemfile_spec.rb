# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::DependencyLinker::Parser::Gemfile do
  describe '#parse' do
    let(:file_content) do
      <<-CONTENT.strip_heredoc
        source 'https://rubygems.org'

        gem "rails", '4.2.6', github: "rails/rails"
        gem 'rails-deprecated_sanitizer', '~> 1.0.3'
        gem 'responders', '~> 2.0', :github => 'rails/responders'
        gem 'sprockets', '~> 3.6.0', git: 'https://gitlab.example.com/gems/sprockets'
        gem 'default_value_for', '~> 3.0.0'
      CONTENT
    end

    subject { described_class.new(file_content).parse(keyword: 'gem') }

    def fetch_package(name)
      subject.find { |package| package.name == name }
    end

    it 'returns parsed packages' do
      expect(subject.size).to eq(5)
      expect(subject).to all(be_a(Gitlab::DependencyLinker::Package))
    end

    it 'packages respond to name and external_ref accordingly' do
      expect(fetch_package('rails')).to have_attributes(name: 'rails',
        github_ref: 'rails/rails',
        git_ref: nil)

      expect(fetch_package('sprockets')).to have_attributes(name: 'sprockets',
        github_ref: nil,
        git_ref: 'https://gitlab.example.com/gems/sprockets')

      expect(fetch_package('default_value_for')).to have_attributes(name: 'default_value_for',
        github_ref: nil,
        git_ref: nil)
    end
  end
end
