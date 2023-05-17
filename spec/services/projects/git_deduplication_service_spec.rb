# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GitDeduplicationService, feature_category: :source_code_management do
  include ExclusiveLeaseHelpers

  let(:pool) { create(:pool_repository, :ready) }
  let(:project) { create(:project, :repository) }
  let(:lease_key) { "git_deduplication:#{project.id}" }
  let(:lease_timeout) { Projects::GitDeduplicationService::LEASE_TIMEOUT }

  subject(:service) { described_class.new(project) }

  describe '#execute' do
    context 'when there is not already a lease' do
      context 'when the project does not have a pool repository' do
        it 'calls disconnect_git_alternates' do
          stub_exclusive_lease(lease_key, timeout: lease_timeout)

          expect(project.repository).to receive(:disconnect_alternates)

          service.execute
        end
      end

      context 'when the project has a pool repository' do
        let(:project) { create(:project, :repository, pool_repository: pool) }

        context 'when the project is a source project' do
          let(:lease_key) { "git_deduplication:#{pool.source_project.id}" }

          subject(:service) { described_class.new(pool.source_project) }

          it 'calls fetch' do
            stub_exclusive_lease(lease_key, timeout: lease_timeout)
            allow(pool.source_project).to receive(:git_objects_poolable?).and_return(true)

            expect(pool.object_pool).to receive(:fetch)

            service.execute
          end

          it 'does not call fetch if git objects are not poolable' do
            stub_exclusive_lease(lease_key, timeout: lease_timeout)
            allow(pool.source_project).to receive(:git_objects_poolable?).and_return(false)

            expect(pool.object_pool).not_to receive(:fetch)

            service.execute
          end

          it 'does not call fetch if pool and project are not on the same storage' do
            stub_exclusive_lease(lease_key, timeout: lease_timeout)
            allow(pool.source_project.repository).to receive(:storage).and_return('special_storage_001')

            expect(pool.object_pool).not_to receive(:fetch)

            service.execute
          end

          context 'when visibility level of the project' do
            before do
              allow(pool.source_project).to receive(:repository_access_level).and_return(ProjectFeature::ENABLED)
            end

            context 'is private' do
              it 'does not call fetch' do
                allow(pool.source_project).to receive(:visibility_level).and_return(Gitlab::VisibilityLevel::PRIVATE)
                expect(pool.object_pool).not_to receive(:fetch)

                service.execute
              end
            end

            context 'is public' do
              it 'calls fetch' do
                allow(pool.source_project).to receive(:visibility_level).and_return(Gitlab::VisibilityLevel::PUBLIC)
                expect(pool.object_pool).to receive(:fetch)

                service.execute
              end
            end

            context 'is internal' do
              it 'calls fetch' do
                allow(pool.source_project).to receive(:visibility_level).and_return(Gitlab::VisibilityLevel::INTERNAL)
                expect(pool.object_pool).to receive(:fetch)

                service.execute
              end
            end
          end

          context 'when the repository access level' do
            before do
              allow(pool.source_project).to receive(:visibility_level).and_return(Gitlab::VisibilityLevel::PUBLIC)
            end

            context 'is private' do
              it 'does not call fetch' do
                allow(pool.source_project).to receive(:repository_access_level).and_return(ProjectFeature::PRIVATE)

                expect(pool.object_pool).not_to receive(:fetch)

                service.execute
              end
            end

            context 'is greater than private' do
              it 'calls fetch' do
                allow(pool.source_project).to receive(:repository_access_level).and_return(ProjectFeature::PUBLIC)

                expect(pool.object_pool).to receive(:fetch)

                service.execute
              end
            end
          end
        end

        it 'links the repository to the object pool' do
          expect(project).to receive(:link_pool_repository)

          service.execute
        end

        it 'does not link the repository to the object pool if they are not on the same storage' do
          allow(project.repository).to receive(:storage).and_return('special_storage_001')
          expect(project).not_to receive(:link_pool_repository)

          service.execute
        end
      end

      context 'when a lease is already out' do
        before do
          stub_exclusive_lease_taken(lease_key, timeout: lease_timeout)
        end

        it 'fails when a lease is already out' do
          expect(Gitlab::AppJsonLogger).to receive(:error).with({ message: "Cannot obtain an exclusive lease. There must be another instance already in execution.", lease_key: lease_key, class_name: described_class.name, lease_timeout: lease_timeout })

          service.execute
        end
      end
    end
  end
end
