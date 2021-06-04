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

  describe '.find' do
    let_it_be(:project) { create(:project) }
    let_it_be(:other_project) { create(:project) }

    described_class::TEMPLATES_WITH_LATEST_VERSION.keys.each do |key|
      it "finds the latest template for #{key}" do
        result = described_class.find(key, project)
        expect(result.full_name).to eq("#{key}.latest.gitlab-ci.yml")
        expect(result.content).to be_present
      end

      context 'when `redirect_to_latest_template` feature flag is disabled' do
        before do
          stub_feature_flags("redirect_to_latest_template_#{key.underscore.tr('/', '_')}".to_sym => false)
        end

        it "finds the stable template for #{key}" do
          result = described_class.find(key, project)
          expect(result.full_name).to eq("#{key}.gitlab-ci.yml")
          expect(result.content).to be_present
        end
      end

      context 'when `redirect_to_latest_template` feature flag is enabled on the project' do
        before do
          stub_feature_flags("redirect_to_latest_template_#{key.underscore.tr('/', '_')}".to_sym => project)
        end

        it "finds the latest template for #{key}" do
          result = described_class.find(key, project)
          expect(result.full_name).to eq("#{key}.latest.gitlab-ci.yml")
          expect(result.content).to be_present
        end
      end

      context 'when `redirect_to_latest_template` feature flag is enabled on the other project' do
        before do
          stub_feature_flags("redirect_to_latest_template_#{key.underscore.tr('/', '_')}".to_sym => other_project)
        end

        it "finds the stable template for #{key}" do
          result = described_class.find(key, project)
          expect(result.full_name).to eq("#{key}.gitlab-ci.yml")
          expect(result.content).to be_present
        end
      end
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
