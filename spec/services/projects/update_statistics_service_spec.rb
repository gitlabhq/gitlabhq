# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::UpdateStatisticsService, feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax

  let(:service) { described_class.new(project, nil, statistics: statistics) }
  let(:statistics) { %w[repository_size] }

  describe '#execute' do
    context 'with a non-existing project' do
      let(:project) { nil }

      it 'does nothing' do
        expect_any_instance_of(ProjectStatistics).not_to receive(:refresh!)

        service.execute
      end
    end

    context 'with an existing project' do
      let_it_be(:project) { create(:project) }

      where(:statistics, :method_caches) do
        []                                                   | %i[size recent_objects_size commit_count]
        ['repository_size']                                  | %i[size recent_objects_size]
        [:repository_size]                                   | %i[size recent_objects_size]
        [:lfs_objects_size]                                  | nil
        [:commit_count]                                      | [:commit_count]
        [:repository_size, :commit_count]                    | %i[size recent_objects_size commit_count]
        [:repository_size, :commit_count, :lfs_objects_size] | %i[size recent_objects_size commit_count]
      end

      with_them do
        it 'refreshes the project statistics' do
          expect(project.statistics).to receive(:refresh!).with(only: statistics.map(&:to_sym)).and_call_original

          service.execute
        end

        it 'invalidates the method caches after a refresh' do
          expect(project.wiki.repository).not_to receive(:expire_method_caches)

          if method_caches.present?
            expect(project.repository).to receive(:expire_method_caches).with(method_caches).and_call_original
          else
            expect(project.repository).not_to receive(:expire_method_caches)
          end

          service.execute
        end
      end
    end

    context 'with an existing project with a Wiki' do
      let(:project) { create(:project, :repository, :wiki_enabled) }
      let(:statistics) { [:wiki_size] }

      it 'invalidates and refreshes Wiki size' do
        expect(project.statistics).to receive(:refresh!).with(only: statistics).and_call_original
        expect(project.wiki.repository).to receive(:expire_method_caches).with(%i[size]).and_call_original

        service.execute
      end
    end
  end
end
