# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Template::Finders::RepoTemplateFinder do
  let_it_be(:project) { create(:project, :repository) }

  let(:categories) { { 'HTML' => 'html' } }

  subject(:finder) { described_class.new(project, 'files/', '.html', categories) }

  describe '#read' do
    it 'returns the content of the given path' do
      result = finder.read('files/html/500.html')

      expect(result).to be_present
    end

    it 'raises an error if the path does not exist' do
      expect { finder.read('does/not/exist') }.to raise_error(described_class::FileNotFoundError)
    end
  end

  describe '#find' do
    it 'returns the full path of the found template' do
      result = finder.find('500')

      expect(result).to eq('files/html/500.html')
    end

    it 'does not permit path traversal requests' do
      expect { finder.find('../foo') }.to raise_error(/Invalid path/)
    end
  end

  describe '#list_files_for' do
    it 'returns the full path of the found files' do
      result = finder.list_files_for('files/html')

      expect(result).to contain_exactly('files/html/500.html')
    end
  end
end
