# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../scripts/coverage/path_normalizer'

RSpec.describe PathNormalizer, feature_category: :tooling do
  using RSpec::Parameterized::TableSyntax

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

    context 'with a relative path whose gitlab subdirectory shares a project root directory name' do
      where(:path) do
        [
          'lib/gitlab/config/loader/yaml.rb',
          'lib/gitlab/ci/config/entry/job.rb',
          'ee/lib/gitlab/config/entry/factory.rb',
          'lib/gitlab/spec/helper.rb'
        ]
      end

      with_them do
        it 'leaves the path unchanged' do
          expect(described_class.normalize(path)).to eq(path)
        end
      end
    end

    context 'with a Crystalball ./-prefixed path whose gitlab subdirectory shares a project root directory name' do
      where(:path, :expected) do
        [
          ['./lib/gitlab/config/loader/yaml.rb', 'lib/gitlab/config/loader/yaml.rb'],
          ['./ee/lib/gitlab/config/entry/factory.rb', 'ee/lib/gitlab/config/entry/factory.rb'],
          ['./lib/gitlab/spec/helper.rb', 'lib/gitlab/spec/helper.rb']
        ]
      end

      with_them do
        it 'strips only the ./ prefix' do
          expect(described_class.normalize(path)).to eq(expected)
        end
      end
    end

    context 'with a container path whose gitlab subdirectory shares a project root directory name' do
      where(:path, :expected) do
        [
          ['/builds/gitlab-org/gitlab/lib/gitlab/config/loader/yaml.rb', 'lib/gitlab/config/loader/yaml.rb'],
          ['/builds/gitlab-org/gitlab/lib/gitlab/ci/config/entry/job.rb', 'lib/gitlab/ci/config/entry/job.rb'],
          ['/builds/gitlab-org/gitlab/ee/lib/gitlab/config/entry/factory.rb', 'ee/lib/gitlab/config/entry/factory.rb']
        ]
      end

      with_them do
        it 'strips only the container prefix' do
          expect(described_class.normalize(path)).to eq(expected)
        end
      end
    end
  end
end
