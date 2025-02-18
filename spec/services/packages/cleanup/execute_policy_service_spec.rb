# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Cleanup::ExecutePolicyService, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:policy) { create(:packages_cleanup_policy, project: project) }

  let(:service) { described_class.new(policy) }

  describe '#execute' do
    subject(:execute) { service.execute }

    context 'with the keep_n_duplicated_files parameter' do
      let_it_be(:package1) { create(:generic_package, project: project) }
      let_it_be(:package2) { create(:generic_package, project: project) }
      let_it_be(:package3) { create(:generic_package, project: project) }
      let_it_be(:package4) { create(:generic_package, :pending_destruction, project: project) }

      let_it_be(:package_file1_1) { create(:package_file, package: package1, file_name: 'file_name1') }
      let_it_be(:package_file1_2) { create(:package_file, package: package1, file_name: 'file_name1') }
      let_it_be(:package_file1_3) { create(:package_file, package: package1, file_name: 'file_name1') }

      let_it_be(:package_file1_4) { create(:package_file, package: package1, file_name: 'file_name2') }
      let_it_be(:package_file1_5) { create(:package_file, package: package1, file_name: 'file_name2') }
      let_it_be(:package_file1_6) { create(:package_file, package: package1, file_name: 'file_name2') }
      let_it_be(:package_file1_7) do
        create(:package_file, :pending_destruction, package: package1, file_name: 'file_name2')
      end

      let_it_be(:package_file2_1) { create(:package_file, package: package2, file_name: 'file_name1') }
      let_it_be(:package_file2_2) { create(:package_file, package: package2, file_name: 'file_name1') }
      let_it_be(:package_file2_3) { create(:package_file, package: package2, file_name: 'file_name1') }
      let_it_be(:package_file2_4) { create(:package_file, package: package2, file_name: 'file_name1') }

      let_it_be(:package_file3_1) { create(:package_file, package: package3, file_name: 'file_name_test') }

      let_it_be(:package_file4_1) { create(:package_file, package: package4, file_name: 'file_name1') }
      let_it_be(:package_file4_2) { create(:package_file, package: package4, file_name: 'file_name1') }

      let(:package_files_1) { package1.package_files.installable }
      let(:package_files_2) { package2.package_files.installable }
      let(:package_files_3) { package3.package_files.installable }

      context 'when set to less than the total number of duplicated files' do
        before do
          # for each package file duplicate, we keep only the most recent one
          policy.update!(keep_n_duplicated_package_files: '1')
        end

        shared_examples 'keeping the most recent package files' do
          let(:response_payload) do
            {
              counts: {
                marked_package_files_total_count: 7,
                unique_package_id_and_file_name_total_count: 3
              },
              timeout: false
            }
          end

          it 'only keeps the most recent package files' do
            expect { execute }.to change { ::Packages::PackageFile.installable.count }.by(-7)

            expect(package_files_1).to contain_exactly(package_file1_3, package_file1_6)
            expect(package_files_2).to contain_exactly(package_file2_4)
            expect(package_files_3).to contain_exactly(package_file3_1)

            expect(execute).to be_success
            expect(execute.message).to eq("Packages cleanup policy executed for project #{project.id}")
            expect(execute.payload).to eq(response_payload)
          end
        end

        it_behaves_like 'keeping the most recent package files'

        context 'when the service needs to loop' do
          before do
            stub_const("#{described_class.name}::DUPLICATED_FILES_BATCH_SIZE", 2)
          end

          it_behaves_like 'keeping the most recent package files' do
            before do
              expect(::Packages::MarkPackageFilesForDestructionService)
                .to receive(:new).exactly(3).times.and_call_original
            end
          end

          context 'when a timeout is hit' do
            let(:response_payload) do
              {
                counts: {
                  marked_package_files_total_count: 4,
                  unique_package_id_and_file_name_total_count: 3
                },
                timeout: true
              }
            end

            let(:service_timeout_response) do
              ServiceResponse.error(
                message: 'Timeout while marking package files as pending destruction',
                payload: { marked_package_files_count: 0 }
              )
            end

            before do
              mock_service_timeout(on_iteration: 3)
            end

            it 'keeps part of the most recent package files' do
              expect { execute }
                .to change { ::Packages::PackageFile.installable.count }.by(-4)
                .and not_change { package_files_2.count } # untouched because of the timeout
                .and not_change { package_files_3.count } # untouched because of the timeout

              expect(package_files_1).to contain_exactly(package_file1_3, package_file1_6)
              expect(execute).to be_success
              expect(execute.message).to eq("Packages cleanup policy executed for project #{project.id}")
              expect(execute.payload).to eq(response_payload)
            end

            def mock_service_timeout(on_iteration:)
              execute_call_count = 1
              expect_next_instances_of(::Packages::MarkPackageFilesForDestructionService, 3) do |service|
                expect(service).to receive(:execute).and_wrap_original do |m, *args, **kwargs|
                  # timeout if we are on the right iteration
                  if execute_call_count == on_iteration
                    service_timeout_response
                  else
                    execute_call_count += 1
                    m.call(*args, **kwargs)
                  end
                end
              end
            end
          end
        end
      end

      context 'when set to more than the total number of duplicated files' do
        before do
          # using the biggest value for keep_n_duplicated_package_files
          policy.update!(keep_n_duplicated_package_files: '50')
        end

        it 'keeps all package files' do
          expect { execute }.not_to change { ::Packages::PackageFile.installable.count }
        end
      end

      context 'when set to all' do
        before do
          policy.update!(keep_n_duplicated_package_files: 'all')
        end

        it 'skips the policy' do
          expect(::Packages::MarkPackageFilesForDestructionService).not_to receive(:new)
          expect { execute }.not_to change { ::Packages::PackageFile.installable.count }
        end
      end

      context 'for conan packages' do
        let_it_be(:conan_package) { create(:conan_package, project: project) }
        let(:manifest_filename) { ::Packages::Conan::FileMetadatum::CONAN_MANIFEST }

        before do
          policy.update!(keep_n_duplicated_package_files: '1')
        end

        context 'with recipe & package manifest files' do
          it 'keeps the two manifest files' do
            expect { execute }.not_to change {
              conan_package.package_files.installable.with_file_name(manifest_filename).count
            }
          end
        end

        context 'with multiple recipe files' do
          let_it_be(:conan_recipe_manifest) do
            create(:conan_package_file, :conan_recipe_manifest, package: conan_package)
          end

          let_it_be(:conan_package_manifest) do
            create(:conan_package_file, :conan_package_manifest, package: conan_package)
          end

          it 'keeps the most recent recipe files' do
            expect { execute }.to change { conan_package.package_files.installable.count }.by(-2)
            expect(conan_package.package_files.installable.with_file_name(manifest_filename)).to contain_exactly(
              conan_recipe_manifest, conan_package_manifest
            )
          end
        end
      end
    end
  end
end
