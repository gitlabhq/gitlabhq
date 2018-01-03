require 'spec_helper'

describe Gitlab::Template::GitlabCiYmlTemplate do
  subject { described_class }

  describe '.all' do
    it 'strips the gitlab-ci suffix' do
      expect(subject.all.first.name).not_to end_with('.gitlab-ci.yml')
    end

    it 'combines the globals and rest' do
      all = subject.all.map(&:name)

      expect(all).to include('Elixir')
      expect(all).to include('Docker')
      expect(all).to include('Ruby')
    end
  end

  describe '.find' do
    it 'returns nil if the file does not exist' do
      expect(subject.find('mepmep-yadida')).to be nil
    end

    it 'returns the GitlabCiYml object of a valid file' do
      ruby = subject.find('Ruby')

      expect(ruby).to be_a described_class
      expect(ruby.name).to eq('Ruby')
    end
  end

  describe '.by_category' do
    it 'returns sorted results' do
      result = described_class.by_category('General')

      expect(result).to eq(result.sort)
    end
  end

  describe '#content' do
    it 'loads the full file' do
      gitignore = subject.new(Rails.root.join('vendor/gitlab-ci-yml/Ruby.gitlab-ci.yml'))

      expect(gitignore.name).to eq 'Ruby'
      expect(gitignore.content).to start_with('#')
    end
  end

  describe '#<=>' do
    it 'sorts lexicographically' do
      one = described_class.new('a.gitlab-ci.yml')
      other = described_class.new('z.gitlab-ci.yml')

      expect(one.<=>(other)).to be(-1)
      expect([other, one].sort).to eq([one, other])
    end
  end
end
