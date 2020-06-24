# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Template::GitignoreTemplate do
  subject { described_class }

  describe '.all' do
    it 'strips the gitignore suffix' do
      expect(subject.all.first.name).not_to end_with('.gitignore')
    end

    it 'combines the globals and rest' do
      all = subject.all.map(&:name)

      expect(all).to include('Vim')
      expect(all).to include('Ruby')
    end
  end

  describe '.find' do
    it 'returns nil if the file does not exist' do
      expect(subject.find('mepmep-yadida')).to be nil
    end

    it 'returns the Gitignore object of a valid file' do
      ruby = subject.find('Ruby')

      expect(ruby).to be_a described_class
      expect(ruby.name).to eq('Ruby')
    end
  end

  describe '#content' do
    it 'loads the full file' do
      gitignore = subject.new(Rails.root.join('vendor/gitignore/Ruby.gitignore'))

      expect(gitignore.name).to eq 'Ruby'
      expect(gitignore.content).to start_with('*.gem')
    end
  end
end
