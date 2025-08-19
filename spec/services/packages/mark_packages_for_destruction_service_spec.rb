# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::MarkPackagesForDestructionService, :sidekiq_inline, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:packages) { create_list(:nuget_package, 3, project: project) }

  let(:user) { project.owner }

  # The service only accepts ActiveRecord relationships and not arrays.
  let(:service) { described_class.new(packages: ::Packages::Package.id_in(package_ids), current_user: user) }
  let(:package_ids) { packages.map(&:id) }

  describe '#execute' do
    subject { service.execute }

    shared_examples 'returning service response' do |status:, message:, reason: nil|
      it 'returns service response' do
        subject

        expect(subject).to be_a(ServiceResponse)
        expect(subject.status).to eq(status)
        expect(subject.message).to eq(message)
        expect(subject.reason).to eq(reason) if reason
      end
    end

    context 'when the user is authorized' do
      before do
        project.add_maintainer(user)
      end

      context 'when it is successful' do
        it 'marks the packages as pending destruction' do
          expect(::Packages::Maven::Metadata::SyncService).not_to receive(:new)
          expect(::Packages::Npm::CreateMetadataCacheService).not_to receive(:new)

          expect { subject }.to change { ::Packages::Package.pending_destruction.count }.from(0).to(3)
                                  .and change { Packages::PackageFile.pending_destruction.count }.from(0).to(3)
          packages.each { |pkg| expect(pkg.reload).to be_pending_destruction }
        end

        it_behaves_like 'returning service response', status: :success,
          message: 'Packages were successfully marked as pending destruction'

        context 'with maven packages' do
          let_it_be_with_reload(:packages) { create_list(:maven_package, 3, project: project) }

          it 'marks the packages as pending destruction' do
            expect(::Packages::Maven::Metadata::SyncService).to receive(:new).once.and_call_original

            expect { subject }.to change { ::Packages::Package.pending_destruction.count }.from(0).to(3)
                                    .and change { Packages::PackageFile.pending_destruction.count }.from(0).to(9)
            packages.each { |pkg| expect(pkg.reload).to be_pending_destruction }
          end

          it_behaves_like 'returning service response', status: :success,
            message: 'Packages were successfully marked as pending destruction'

          context 'without version' do
            before do
              ::Packages::Package.id_in(package_ids).update_all(version: nil)
            end

            it 'marks the packages as pending destruction' do
              expect(::Packages::Maven::Metadata::SyncService).not_to receive(:new)

              expect { subject }.to change { ::Packages::Package.pending_destruction.count }.from(0).to(3)
                                      .and change { Packages::PackageFile.pending_destruction.count }.from(0).to(9)
              packages.each { |pkg| expect(pkg.reload).to be_pending_destruction }
            end

            it_behaves_like 'returning service response', status: :success,
              message: 'Packages were successfully marked as pending destruction'
          end
        end

        context 'with npm packages' do
          let_it_be_with_reload(:packages) { create_list(:npm_package, 3, project: project, name: 'test-package') }

          it 'creates npm metadata' do
            expect(::Packages::Npm::CreateMetadataCacheService).to receive(:new).once.and_call_original

            expect { subject }.to change { ::Packages::Package.pending_destruction.count }.from(0).to(3)
                                    .and change { Packages::PackageFile.pending_destruction.count }.from(0).to(3)
            packages.each { |package| expect(package.reload).to be_pending_destruction }
          end

          it_behaves_like 'returning service response', status: :success,
            message: 'Packages were successfully marked as pending destruction'
        end

        context 'with helm packages' do
          let_it_be_with_reload(:packages) do
            create_list(:helm_package, 3, project: project, without_package_files: true)
          end

          let_it_be(:package_file1) { create(:helm_package_file, package: packages[0], channel: 'stable') }
          let_it_be(:package_file2) { create(:helm_package_file, package: packages[1], channel: 'test') }
          let_it_be(:package_file3) { create(:helm_package_file, package: packages[2], channel: 'dev') }

          it 'marks the packages as pending destruction', :aggregate_failures do
            expect { subject }.to change { ::Packages::Package.pending_destruction.count }.from(0).to(3)
                                    .and change { Packages::PackageFile.pending_destruction.count }.from(0).to(3)
            packages.each { |package| expect(package.reload).to be_pending_destruction }
          end

          it 'creates helm metadata for the project and channel' do
            expect(::Packages::Helm::CreateMetadataCacheService).to receive(:new).with(
              project, 'stable'
            ).once.and_call_original
            expect(::Packages::Helm::CreateMetadataCacheService).to receive(:new).with(
              project, 'test'
            ).once.and_call_original
            expect(::Packages::Helm::CreateMetadataCacheService).to receive(:new).with(
              project, 'dev'
            ).once.and_call_original

            subject
          end

          it_behaves_like 'returning service response', status: :success,
            message: 'Packages were successfully marked as pending destruction'
        end
      end

      context 'when it is not successful' do
        before do
          allow(service).to receive(:can_destroy_packages?).and_raise(StandardError, 'test')
        end

        it 'does not mark the packages as pending destruction' do
          expect(::Packages::Maven::Metadata::SyncService).not_to receive(:new)

          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
            instance_of(StandardError),
            package_ids: package_ids
          )

          expect { subject }.to not_change { ::Packages::Package.pending_destruction.count }
                                  .and not_change { ::Packages::PackageFile.pending_destruction.count }
        end

        it_behaves_like 'returning service response', status: :error,
          message: 'Failed to mark the packages as pending destruction'
      end
    end

    context 'when the user is not authorized' do
      let(:user) { nil }

      it 'does not mark the packages as pending destruction' do
        expect(::Packages::Maven::Metadata::SyncService).not_to receive(:new)

        expect { subject }.to not_change { ::Packages::Package.pending_destruction.count }
                                .and not_change { ::Packages::PackageFile.pending_destruction.count }
      end

      it_behaves_like 'returning service response', status: :error, reason: :unauthorized,
        message: "You don't have the permission to perform this action"
    end
  end
end
