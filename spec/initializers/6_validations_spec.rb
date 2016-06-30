require 'spec_helper'

describe '6_validations', lib: true do
  context 'with correct settings' do
    before do
      mock_storages('foo' => '/a/b/c', 'bar' => 'a/b/d')
    end

    it 'passes through' do
      expect { load_validations }.not_to raise_error
    end
  end

  context 'with invalid storage names' do
    before do
      mock_storages('name with spaces' => '/a/b/c')
    end

    it 'throws an error' do
      expect { load_validations }.to raise_error('"name with spaces" is not a valid storage name. Please fix this in your gitlab.yml before starting GitLab.')
    end
  end

  context 'with nested storage paths' do
    before do
      mock_storages('foo' => '/a/b/c', 'bar' => '/a/b/c/d')
    end

    it 'throws an error' do
      expect { load_validations }.to raise_error('bar is a nested path of foo. Nested paths are not supported for repository storages. Please fix this in your gitlab.yml before starting GitLab.')
    end
  end

  def mock_storages(storages)
    allow(Gitlab.config.repositories).to receive(:storages).and_return(storages)
  end

  def load_validations
    load File.join(__dir__, '../../config/initializers/6_validations.rb')
  end
end
