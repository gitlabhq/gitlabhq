# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::MarkPackagesForDestructionService, :sidekiq_inline, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:packages) { create_list(:npm_package, 3, project: project) }

  let(:user) { project.owner }

  # The service only accepts ActiveRecord relationships and not arrays.
  let(:service) { described_class.new(packages: ::Packages::Package.id_in(package_ids), current_user: user) }
  let(:package_ids) { packages.map(&:id) }

  describe '#execute' do
    subject { service.execute }

    context 'when the user is authorized' do
      before do
        project.add_maintainer(user)
      end

      context 'when it is successful' do
        it 'marks the packages as pending destruction' do
          expect(::Packages::Maven::Metadata::SyncService).not_to receive(:new)

          expect { subject }.to change { ::Packages::Package.pending_destruction.count }.from(0).to(3)
                                  .and change { Packages::PackageFile.pending_destruction.count }.from(0).to(3)
          packages.each { |pkg| expect(pkg.reload).to be_pending_destruction }

          expect(subject).to be_a(ServiceResponse)
          expect(subject).to be_success
          expect(subject.message).to eq('Packages were successfully marked as pending destruction')
        end

        context 'with maven packages' do
          let_it_be_with_reload(:packages) { create_list(:maven_package, 3, project: project) }

          it 'marks the packages as pending destruction' do
            expect(::Packages::Maven::Metadata::SyncService).to receive(:new).once.and_call_original

            expect { subject }.to change { ::Packages::Package.pending_destruction.count }.from(0).to(3)
                                    .and change { Packages::PackageFile.pending_destruction.count }.from(0).to(9)
            packages.each { |pkg| expect(pkg.reload).to be_pending_destruction }

            expect(subject).to be_a(ServiceResponse)
            expect(subject).to be_success
            expect(subject.message).to eq('Packages were successfully marked as pending destruction')
          end

          context 'without version' do
            before do
              ::Packages::Package.id_in(package_ids).update_all(version: nil)
            end

            it 'marks the packages as pending destruction' do
              expect(::Packages::Maven::Metadata::SyncService).not_to receive(:new)

              expect { subject }.to change { ::Packages::Package.pending_destruction.count }.from(0).to(3)
                                      .and change { Packages::PackageFile.pending_destruction.count }.from(0).to(9)
              packages.each { |pkg| expect(pkg.reload).to be_pending_destruction }

              expect(subject).to be_a(ServiceResponse)
              expect(subject).to be_success
              expect(subject.message).to eq('Packages were successfully marked as pending destruction')
            end
          end
        end
      end

      context 'when it is not successful' do
        before do
          allow(service).to receive(:can_destroy_packages?).and_raise(StandardError, 'test')
        end

        it 'returns an error ServiceResponse' do
          expect(::Packages::Maven::Metadata::SyncService).not_to receive(:new)

          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
            instance_of(StandardError),
            package_ids: package_ids
          )

          expect { subject }.to not_change { ::Packages::Package.pending_destruction.count }
                                  .and not_change { ::Packages::PackageFile.pending_destruction.count }

          expect(subject).to be_a(ServiceResponse)
          expect(subject).to be_error
          expect(subject.message).to eq("Failed to mark the packages as pending destruction")
          expect(subject.status).to eq(:error)
        end
      end
    end

    context 'when the user is not authorized' do
      let(:user) { nil }

      it 'returns an error ServiceResponse' do
        expect(::Packages::Maven::Metadata::SyncService).not_to receive(:new)

        expect { subject }.to not_change { ::Packages::Package.pending_destruction.count }
                                .and not_change { ::Packages::PackageFile.pending_destruction.count }

        expect(subject).to be_a(ServiceResponse)
        expect(subject).to be_error
        expect(subject.message).to eq("You don't have the permission to perform this action")
        expect(subject.status).to eq(:error)
        expect(subject.reason).to eq(:unauthorized)
      end
    end
  end
end
