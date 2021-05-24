# frozen_string_literal: true

RSpec.shared_examples 'Generate Debian Distribution and component files' do
  let_it_be(:component_main) { create("debian_#{container_type}_component", distribution: distribution, name: 'main') }
  let_it_be(:component_contrib) { create("debian_#{container_type}_component", distribution: distribution, name: 'contrib') }

  let_it_be(:architecture_all) { create("debian_#{container_type}_architecture", distribution: distribution, name: 'all') }
  let_it_be(:architecture_amd64) { create("debian_#{container_type}_architecture", distribution: distribution, name: 'amd64') }
  let_it_be(:architecture_arm64) { create("debian_#{container_type}_architecture", distribution: distribution, name: 'arm64') }

  let_it_be(:component_file1) { create("debian_#{container_type}_component_file", component: component_contrib, architecture: architecture_all,   updated_at: '2020-01-24T08:00:00Z', file_sha256: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', file_md5: 'd41d8cd98f00b204e9800998ecf8427e', file_fixture: nil, size: 0) } # updated
  let_it_be(:component_file2) { create("debian_#{container_type}_component_file", component: component_main,    architecture: architecture_all,   updated_at: '2020-01-24T09:00:00Z', file_sha256: 'a') } # destroyed
  let_it_be(:component_file3) { create("debian_#{container_type}_component_file", component: component_main,    architecture: architecture_amd64, updated_at: '2020-01-24T10:54:59Z', file_sha256: 'b') } # destroyed, 1 second before last generation
  let_it_be(:component_file4) { create("debian_#{container_type}_component_file", component: component_contrib, architecture: architecture_all,   updated_at: '2020-01-24T10:55:00Z', file_sha256: 'c') } # kept, last generation
  let_it_be(:component_file5) { create("debian_#{container_type}_component_file", component: component_contrib, architecture: architecture_all,   updated_at: '2020-01-24T10:55:00Z', file_sha256: 'd') } # kept, last generation
  let_it_be(:component_file6) { create("debian_#{container_type}_component_file", component: component_contrib, architecture: architecture_amd64, updated_at: '2020-01-25T15:17:18Z', file_sha256: 'e') } # kept, less than 1 hour ago

  def check_component_file(release_date, component_name, component_file_type, architecture_name, expected_content)
    component_file = distribution
      .component_files
      .with_component_name(component_name)
      .with_file_type(component_file_type)
      .with_architecture_name(architecture_name)
      .order_updated_asc
      .last

    expect(component_file).not_to be_nil
    expect(component_file.updated_at).to eq(release_date)

    unless expected_content.nil?
      component_file.file.use_file do |file_path|
        expect(File.read(file_path)).to eq(expected_content)
      end
    end
  end

  it 'generates Debian distribution and component files', :aggregate_failures do
    current_time = Time.utc(2020, 01, 25, 15, 17, 18, 123456)

    travel_to(current_time) do
      expect(Gitlab::ErrorTracking).not_to receive(:log_exception)

      initial_count = 6
      destroyed_count = 2
      # updated_count = 1
      created_count = 5

      expect { subject }
        .to not_change { Packages::Package.count }
        .and not_change { Packages::PackageFile.count }
        .and change { distribution.reload.updated_at }.to(current_time.round)
        .and change { distribution.component_files.reset.count }.from(initial_count).to(initial_count - destroyed_count + created_count)
        .and change { component_file1.reload.updated_at }.to(current_time.round)

      debs = package.package_files.with_debian_file_type(:deb).preload_debian_file_metadata.to_a
      pool_prefix = "pool/unstable/#{project.id}/p/#{package.name}"
      expected_main_amd64_content = <<~EOF
      Package: libsample0
      Source: #{package.name}
      Version: #{package.version}
      Installed-Size: 7
      Maintainer: #{debs[0].debian_fields['Maintainer']}
      Architecture: amd64
      Description: Some mostly empty lib
       Used in GitLab tests.
       .
       Testing another paragraph.
      Multi-Arch: same
      Homepage: #{debs[0].debian_fields['Homepage']}
      Section: libs
      Priority: optional
      Filename: #{pool_prefix}/libsample0_1.2.3~alpha2_amd64.deb
      Size: 409600
      MD5sum: #{debs[0].file_md5}
      SHA256: #{debs[0].file_sha256}

      Package: sample-dev
      Source: #{package.name} (#{package.version})
      Version: 1.2.3~binary
      Installed-Size: 7
      Maintainer: #{debs[1].debian_fields['Maintainer']}
      Architecture: amd64
      Depends: libsample0 (= 1.2.3~binary)
      Description: Some mostly empty development files
       Used in GitLab tests.
       .
       Testing another paragraph.
      Multi-Arch: same
      Homepage: #{debs[1].debian_fields['Homepage']}
      Section: libdevel
      Priority: optional
      Filename: #{pool_prefix}/sample-dev_1.2.3~binary_amd64.deb
      Size: 409600
      MD5sum: #{debs[1].file_md5}
      SHA256: #{debs[1].file_sha256}
      EOF

      check_component_file(current_time.round, 'main', :packages, 'all', nil)
      check_component_file(current_time.round, 'main', :packages, 'amd64', expected_main_amd64_content)
      check_component_file(current_time.round, 'main', :packages, 'arm64', nil)

      check_component_file(current_time.round, 'contrib', :packages, 'all', nil)
      check_component_file(current_time.round, 'contrib', :packages, 'amd64', nil)
      check_component_file(current_time.round, 'contrib', :packages, 'arm64', nil)

      main_amd64_size = expected_main_amd64_content.length
      main_amd64_md5sum = Digest::MD5.hexdigest(expected_main_amd64_content)
      main_amd64_sha256 = Digest::SHA256.hexdigest(expected_main_amd64_content)

      contrib_all_size = component_file1.size
      contrib_all_md5sum = component_file1.file_md5
      contrib_all_sha256 = component_file1.file_sha256

      expected_release_content = <<~EOF
      Codename: unstable
      Date: Sat, 25 Jan 2020 15:17:18 +0000
      Valid-Until: Mon, 27 Jan 2020 15:17:18 +0000
      Architectures: all amd64 arm64
      Components: contrib main
      MD5Sum:
       #{contrib_all_md5sum}        #{contrib_all_size} contrib/binary-all/Packages
       d41d8cd98f00b204e9800998ecf8427e        0 contrib/binary-amd64/Packages
       d41d8cd98f00b204e9800998ecf8427e        0 contrib/binary-arm64/Packages
       d41d8cd98f00b204e9800998ecf8427e        0 main/binary-all/Packages
       #{main_amd64_md5sum}     #{main_amd64_size} main/binary-amd64/Packages
       d41d8cd98f00b204e9800998ecf8427e        0 main/binary-arm64/Packages
      SHA256:
       #{contrib_all_sha256}        #{contrib_all_size} contrib/binary-all/Packages
       e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855        0 contrib/binary-amd64/Packages
       e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855        0 contrib/binary-arm64/Packages
       e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855        0 main/binary-all/Packages
       #{main_amd64_sha256}     #{main_amd64_size} main/binary-amd64/Packages
       e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855        0 main/binary-arm64/Packages
      EOF

      distribution.file.use_file do |file_path|
        expect(File.read(file_path)).to eq(expected_release_content)
      end
    end
  end
end

RSpec.shared_examples 'Generate minimal Debian Distribution' do
  it 'generates minimal distribution', :aggregate_failures do
    travel_to(Time.utc(2020, 01, 25, 15, 17, 18, 123456)) do
      expect(Gitlab::ErrorTracking).not_to receive(:log_exception)

      expect { subject }
        .to not_change { Packages::Package.count }
        .and not_change { Packages::PackageFile.count }
        .and not_change { distribution.component_files.reset.count }

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
