# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../scripts/coverage/path_normalizer'

RSpec.describe PathNormalizer, feature_category: :tooling do
  describe '.normalize' do
    it 'returns nil for nil input' do
      expect(described_class.normalize(nil)).to be_nil
    end

    it 'returns empty string for empty input' do
      expect(described_class.normalize('')).to eq('')
    end

    it 'strips absolute path prefix up to /gitlab/' do
      expect(described_class.normalize('/builds/gitlab-org/gitlab/app/models/user.rb'))
        .to eq('app/models/user.rb')
    end

    it 'strips GDK-style absolute paths' do
      expect(described_class.normalize('/home/gdk/gitlab-development-kit/gitlab/lib/api/api.rb'))
        .to eq('lib/api/api.rb')
    end

    it 'strips ./ prefix' do
      expect(described_class.normalize('./app/models/user.rb'))
        .to eq('app/models/user.rb')
    end

    it 'strips both absolute path and ./ prefix' do
      expect(described_class.normalize('/builds/gitlab-org/gitlab/./app/models/user.rb'))
        .to eq('app/models/user.rb')
    end

    it 'leaves clean relative paths unchanged' do
      expect(described_class.normalize('app/models/user.rb'))
        .to eq('app/models/user.rb')
    end

    it 'handles paths with multiple /gitlab/ segments' do
      expect(described_class.normalize('/gitlab/builds/gitlab-org/gitlab/app/models/user.rb'))
        .to eq('app/models/user.rb')
    end

    it 'preserves gitlab subdirectories within the project' do
      expect(described_class.normalize('/builds/gitlab-org/gitlab/lib/gitlab/api.rb'))
        .to eq('lib/gitlab/api.rb')
    end

    it 'preserves deeply nested gitlab subdirectories' do
      expect(described_class.normalize('/builds/gitlab-org/gitlab/lib/gitlab/ci/config.rb'))
        .to eq('lib/gitlab/ci/config.rb')
    end

    it 'handles ee directory paths' do
      expect(described_class.normalize('/builds/gitlab-org/gitlab/ee/app/models/license.rb'))
        .to eq('ee/app/models/license.rb')
    end

    it 'handles spec directory paths' do
      expect(described_class.normalize('/builds/gitlab-org/gitlab/spec/models/user_spec.rb'))
        .to eq('spec/models/user_spec.rb')
    end

    it 'handles qa directory paths' do
      expect(described_class.normalize('/builds/gitlab-org/gitlab/qa/qa/page/main/login.rb'))
        .to eq('qa/qa/page/main/login.rb')
    end
  end
end
