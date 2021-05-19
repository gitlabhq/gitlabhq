# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Debian::GenerateDistributionService do
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:project_distribution) { create("debian_project_distribution", container: project, codename: 'unstable', valid_time_duration_seconds: 48.hours.to_i) }

  let_it_be(:incoming) { create(:debian_incoming, project: project) }

  before_all do
    ::Packages::Debian::ProcessChangesService.new(incoming.package_files.last, nil).execute
  end

  let(:service) { described_class.new(distribution) }

  describe '#execute' do
    subject { service.execute }

    shared_examples 'Generate Distribution' do |container_type|
      context "for #{container_type}" do
        if container_type == :group
          let_it_be(:container) { group }
          let_it_be(:distribution, reload: true) { create('debian_group_distribution', container: group, codename: 'unstable', valid_time_duration_seconds: 48.hours.to_i) }
        else
          let_it_be(:container) { project }
          let_it_be(:distribution, reload: true) { project_distribution }
        end

        context 'with components and architectures' do
          let_it_be(:component_main   ) { create("debian_#{container_type}_component", distribution: distribution, name: 'main') }
          let_it_be(:component_contrib) { create("debian_#{container_type}_component", distribution: distribution, name: 'contrib') }

          let_it_be(:architecture_all  ) { create("debian_#{container_type}_architecture", distribution: distribution, name: 'all') }
          let_it_be(:architecture_amd64) { create("debian_#{container_type}_architecture", distribution: distribution, name: 'amd64') }
          let_it_be(:architecture_arm64) { create("debian_#{container_type}_architecture", distribution: distribution, name: 'arm64') }

          let_it_be(:component_file1) { create("debian_#{container_type}_component_file", component: component_main,    architecture: architecture_all,   created_at: '2020-01-24T09:00:00.000Z') } # destroyed
          let_it_be(:component_file2) { create("debian_#{container_type}_component_file", component: component_main,    architecture: architecture_amd64, created_at: '2020-01-24T10:29:59.000Z') } # destroyed
          let_it_be(:component_file3) { create("debian_#{container_type}_component_file", component: component_contrib, architecture: architecture_all,   created_at: '2020-01-24T10:30:00.000Z') } # kept
          let_it_be(:component_file4) { create("debian_#{container_type}_component_file", component: component_contrib, architecture: architecture_amd64, created_at: '2020-01-24T11:30:00.000Z') } # kept

          def check_component_file(component_name, component_file_type, architecture_name, expected_content)
            component_file = distribution
              .component_files
              .with_component_name(component_name)
              .with_file_type(component_file_type)
              .with_architecture_name(architecture_name)
              .last

            expect(component_file).not_to be_nil
            expect(component_file.file.exists?).to eq(!expected_content.nil?)

            unless expected_content.nil?
              component_file.file.use_file do |file_path|
                expect(File.read(file_path)).to eq(expected_content)
              end
            end
          end

          it 'updates distribution and component files', :aggregate_failures do
            travel_to(Time.utc(2020, 01, 25, 15, 17, 18, 123456)) do
              expect(Gitlab::ErrorTracking).not_to receive(:log_exception)

              expect { subject }
                .to not_change { Packages::Package.count }
                .and not_change { Packages::PackageFile.count }
                .and change { distribution.component_files.count }.from(4).to(2 + 6)

              expected_main_amd64_content = <<~EOF
              Package: libsample0
              Source: sample
              Version: 1.2.3~alpha2
              Installed-Size: 7
              Maintainer: John Doe <john.doe@example.com>
              Architecture: amd64
              Description: Some mostly empty lib
               Used in GitLab tests.
               .
               Testing another paragraph.
              Multi-Arch: same
              Homepage: https://gitlab.com/
              Section: libs
              Priority: optional
              Filename: pool/unstable/#{project.id}/s/sample/libsample0_1.2.3~alpha2_amd64.deb
              Size: 409600
              MD5sum: fb0842b21adc44207996296fe14439dd
              SHA256: 1c383a525bfcba619c7305ccd106d61db501a6bbaf0003bf8d0c429fbdb7fcc1

              Package: sample-dev
              Source: sample (1.2.3~alpha2)
              Version: 1.2.3~binary
              Installed-Size: 7
              Maintainer: John Doe <john.doe@example.com>
              Architecture: amd64
              Depends: libsample0 (= 1.2.3~binary)
              Description: Some mostly empty developpement files
               Used in GitLab tests.
               .
               Testing another paragraph.
              Multi-Arch: same
              Homepage: https://gitlab.com/
              Section: libdevel
              Priority: optional
              Filename: pool/unstable/#{project.id}/s/sample/sample-dev_1.2.3~binary_amd64.deb
              Size: 409600
              MD5sum: d2afbd28e4d74430d22f9504e18bfdf5
              SHA256: 9fbeee2191ce4dab5288fad5ecac1bd369f58fef9a992a880eadf0caf25f086d
              EOF

              check_component_file('main', :packages, 'all', nil)
              check_component_file('main', :packages, 'amd64', expected_main_amd64_content)
              check_component_file('main', :packages, 'arm64', nil)

              check_component_file('contrib', :packages, 'all', nil)
              check_component_file('contrib', :packages, 'amd64', nil)
              check_component_file('contrib', :packages, 'arm64', nil)

              size = expected_main_amd64_content.length
              md5sum = Digest::MD5.hexdigest(expected_main_amd64_content)
              sha256 = Digest::SHA256.hexdigest(expected_main_amd64_content)

              expected_release_content = <<~EOF
              Codename: unstable
              Date: Sat, 25 Jan 2020 15:17:18 +0000
              Valid-Until: Mon, 27 Jan 2020 15:17:18 +0000
              Architectures: all amd64 arm64
              Components: contrib main
              MD5Sum:
               d41d8cd98f00b204e9800998ecf8427e        0 contrib/binary-all/Packages
               d41d8cd98f00b204e9800998ecf8427e        0 contrib/binary-amd64/Packages
               d41d8cd98f00b204e9800998ecf8427e        0 contrib/binary-arm64/Packages
               d41d8cd98f00b204e9800998ecf8427e        0 main/binary-all/Packages
               #{md5sum}     #{size} main/binary-amd64/Packages
               d41d8cd98f00b204e9800998ecf8427e        0 main/binary-arm64/Packages
              SHA256:
               e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855        0 contrib/binary-all/Packages
               e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855        0 contrib/binary-amd64/Packages
               e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855        0 contrib/binary-arm64/Packages
               e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855        0 main/binary-all/Packages
               #{sha256}     #{size} main/binary-amd64/Packages
               e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855        0 main/binary-arm64/Packages
              EOF

              distribution.file.use_file do |file_path|
                expect(File.read(file_path)).to eq(expected_release_content)
              end
            end
          end
        end

        context 'without components and architectures' do
          it 'updates distribution and component files', :aggregate_failures do
            travel_to(Time.utc(2020, 01, 25, 15, 17, 18, 123456)) do
              expect(Gitlab::ErrorTracking).not_to receive(:log_exception)

              expect { subject }
                .to not_change { Packages::Package.count }
                .and not_change { Packages::PackageFile.count }
                .and not_change { distribution.component_files.count }

              expected_release_content = <<~EOF
              Codename: unstable
              Date: Sat, 25 Jan 2020 15:17:18 +0000
              Valid-Until: Mon, 27 Jan 2020 15:17:18 +0000
              MD5Sum:
              SHA256:
              EOF

              distribution.file.use_file do |file_path|
                expect(File.read(file_path)).to eq(expected_release_content)
              end
            end
          end
        end
      end
    end

    it_behaves_like 'Generate Distribution', :project
    it_behaves_like 'Generate Distribution', :group
  end
end
