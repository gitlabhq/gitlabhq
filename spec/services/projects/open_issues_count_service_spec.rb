# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::OpenIssuesCountService, :use_clean_rails_memory_store_caching do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:banned_user) { create(:user, :banned) }

  subject { described_class.new(project, user) }

  it_behaves_like 'a counter caching service'

  before do
    create(:issue, :opened, project: project)
    create(:issue, :opened, confidential: true, project: project)
    create(:issue, :opened, author: banned_user, project: project)
    create(:issue, :closed, project: project)

    described_class.new(project).refresh_cache
  end

  describe '#count' do
    shared_examples 'counts public issues, does not count hidden or confidential' do
      it 'counts only public issues' do
        expect(subject.count).to eq(1)
      end

      it 'uses PUBLIC_COUNT_WITHOUT_HIDDEN_KEY cache key' do
        expect(subject.cache_key).to include('project_open_public_issues_without_hidden_count')
      end
    end

    context 'when user is nil' do
      let(:user) { nil }

      it_behaves_like 'counts public issues, does not count hidden or confidential'
    end

    context 'when user is provided' do
      context 'when user can read confidential issues' do
        before do
          project.add_reporter(user)
        end

        it 'includes confidential issues and does not include hidden issues in count' do
          expect(subject.count).to eq(2)
        end

        it 'uses TOTAL_COUNT_WITHOUT_HIDDEN_KEY cache key' do
          expect(subject.cache_key).to include('project_open_issues_without_hidden_count')
        end
      end

      context 'when user cannot read confidential or hidden issues' do
        before do
          project.add_guest(user)
        end

        it_behaves_like 'counts public issues, does not count hidden or confidential'
      end

      context 'when user is an admin' do
        let_it_be(:user) { create(:user, :admin) }

        context 'when admin mode is enabled', :enable_admin_mode do
          it 'includes confidential and hidden issues in count' do
            expect(subject.count).to eq(3)
          end

          it 'uses TOTAL_COUNT_KEY cache key' do
            expect(subject.cache_key).to include('project_open_issues_including_hidden_count')
          end
        end

        context 'when admin mode is disabled' do
          it_behaves_like 'counts public issues, does not count hidden or confidential'
        end
      end
    end
  end

  describe '#refresh_cache', :aggregate_failures do
    context 'when cache is empty' do
      it 'refreshes cache keys correctly' do
        expect(Rails.cache.read(described_class.new(project).cache_key(described_class::PUBLIC_COUNT_WITHOUT_HIDDEN_KEY))).to eq(1)
        expect(Rails.cache.read(described_class.new(project).cache_key(described_class::TOTAL_COUNT_WITHOUT_HIDDEN_KEY))).to eq(2)
        expect(Rails.cache.read(described_class.new(project).cache_key(described_class::TOTAL_COUNT_KEY))).to eq(3)
      end
    end

    context 'when cache is outdated' do
      it 'refreshes cache keys correctly' do
        create(:issue, :opened, project: project)
        create(:issue, :opened, confidential: true, project: project)
        create(:issue, :opened, author: banned_user, project: project)

        described_class.new(project).refresh_cache

        expect(Rails.cache.read(described_class.new(project).cache_key(described_class::PUBLIC_COUNT_WITHOUT_HIDDEN_KEY))).to eq(2)
        expect(Rails.cache.read(described_class.new(project).cache_key(described_class::TOTAL_COUNT_WITHOUT_HIDDEN_KEY))).to eq(4)
        expect(Rails.cache.read(described_class.new(project).cache_key(described_class::TOTAL_COUNT_KEY))).to eq(6)
      end
    end
  end
end
