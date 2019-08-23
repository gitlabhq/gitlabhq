# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Template::Finders::GlobalTemplateFinder do
  let(:base_dir) { Dir.mktmpdir }

  def create_template!(name_with_category)
    full_path = File.join(base_dir, name_with_category)
    FileUtils.mkdir_p(File.dirname(full_path))
    FileUtils.touch(full_path)
  end

  after do
    FileUtils.rm_rf(base_dir)
  end

  subject(:finder) { described_class.new(base_dir, '', 'Foo' => '', 'Bar' => 'bar') }

  describe '.find' do
    it 'finds a template in the Foo category' do
      create_template!('test-template')

      expect(finder.find('test-template')).to be_present
    end

    it 'finds a template in the Bar category' do
      create_template!('bar/test-template')

      expect(finder.find('test-template')).to be_present
    end

    it 'does not permit path traversal requests' do
      expect { finder.find('../foo') }.to raise_error(/Invalid path/)
    end
  end
end
