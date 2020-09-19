# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Template::GitlabCiYmlTemplate do
  subject { described_class }

  describe '.all' do
    it 'combines the globals and rest' do
      all = subject.all.map(&:name)

      expect(all).to include('Elixir')
      expect(all).to include('Docker')
      expect(all).to include('Ruby')
    end

    it 'does not include Browser-Performance template in FOSS' do
      all = subject.all.map(&:name)

      expect(all).not_to include('Browser-Performance') unless Gitlab.ee?
    end
  end

  describe '#content' do
    it 'loads the full file' do
      gitignore = subject.new(Rails.root.join('lib/gitlab/ci/templates/Ruby.gitlab-ci.yml'))

      expect(gitignore.name).to eq 'Ruby'
      expect(gitignore.content).to start_with('#')
    end
  end

  it_behaves_like 'file template shared examples', 'Ruby', '.gitlab-ci.yml'
end
