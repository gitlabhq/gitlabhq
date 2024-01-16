# frozen_string_literal: true

RSpec.shared_examples 'Generate Debian Distribution and component files' do
  def check_release_files(expected_release_content)
    distribution.reload

    expect(expected_release_content).not_to include('MD5')

    distribution.file.use_file do |file_path|
      expect(File.read(file_path)).to eq(expected_release_content)
    end

    expect(distribution.file_signature).to start_with("-----BEGIN PGP SIGNATURE-----\n")
    expect(distribution.file_signature).to end_with("\n-----END PGP SIGNATURE-----\n")

    distribution.signed_file.use_file do |file_path|
      signed_file_content = File.read(file_path)
      expect(signed_file_content).to start_with("-----BEGIN PGP SIGNED MESSAGE-----\nHash:")
      expect(signed_file_content).to include("\n\n#{expected_release_content}-----BEGIN PGP SIGNATURE-----\n")
      expect(signed_file_content).to end_with("\n-----END PGP SIGNATURE-----\n")
    end
  end

  context 'with Debian components and architectures' do
    let_it_be(:component_main) { create("debian_#{container_type}_component", distribution: distribution, name: 'main') }
    let_it_be(:component_contrib) { create("debian_#{container_type}_component", distribution: distribution, name: 'contrib') }

    let_it_be(:architecture_all) { create("debian_#{container_type}_architecture", distribution: distribution, name: 'all') }
    let_it_be(:architecture_amd64) { create("debian_#{container_type}_architecture", distribution: distribution, name: 'amd64') }
    let_it_be(:architecture_arm64) { create("debian_#{container_type}_architecture", distribution: distribution, name: 'arm64') }

    let_it_be(:component_file_old_main_amd64) { create("debian_#{container_type}_component_file", component: component_main, architecture: architecture_amd64, updated_at: '2020-01-24T08:00:00Z', file_sha256: 'a') } # destroyed

    let_it_be(:component_file_oldest_kept_contrib_all) { create("debian_#{container_type}_component_file", component: component_contrib, architecture: architecture_all, updated_at: '2020-01-24T10:55:00Z', file_sha256: 'b') } # oldest kept
    let_it_be(:component_file_oldest_kept_contrib_amd64) { create("debian_#{container_type}_component_file", component: component_contrib, architecture: architecture_amd64, updated_at: '2020-01-24T10:55:00Z', file_sha256: 'c') } # oldest kept
    let_it_be(:component_file_recent_contrib_amd64) { create("debian_#{container_type}_component_file", component: component_contrib, architecture: architecture_amd64, updated_at: '2020-01-25T15:17:18Z', file_sha256: 'd') } # kept, less than 1 hour ago

    let_it_be(:component_file_empty_contrib_all_di) { create("debian_#{container_type}_component_file", :di_packages, :empty, component: component_contrib, architecture: architecture_all, updated_at: '2020-01-24T10:55:00Z') } # oldest kept
    let_it_be(:component_file_empty_contrib_amd64_di) { create("debian_#{container_type}_component_file", :di_packages, :empty, component: component_contrib, architecture: architecture_amd64, updated_at: '2020-01-24T10:55:00Z') } # touched, as last empty
    let_it_be(:component_file_recent_contrib_amd64_di) { create("debian_#{container_type}_component_file", :di_packages, component: component_contrib, architecture: architecture_amd64, updated_at: '2020-01-25T15:17:18Z', file_sha256: 'f') } # kept, less than 1 hour ago

    let(:pool_prefix) do
      prefix = "pool/#{distribution.codename}"
      prefix += "/#{project.id}" if container_type == :group
      prefix += "/#{package.name[0]}/#{package.name}/#{package.version}"
      prefix
    end

    let(:expected_main_amd64_di_content) do
      <<~MAIN_AMD64_DI_CONTENT
      Section: misc
      Priority: extra
      Filename: #{pool_prefix}/sample-udeb_1.2.3~alpha2_amd64.udeb
      Size: 409600
      SHA256: #{package.package_files.with_debian_file_type(:udeb).first.file_sha256}
      MAIN_AMD64_DI_CONTENT
    end

    let(:expected_main_amd64_di_sha256) { Digest::SHA256.hexdigest(expected_main_amd64_di_content) }
    let!(:component_file_old_main_amd64_di) do # touched
      create("debian_#{container_type}_component_file", :di_packages, component: component_main, architecture: architecture_amd64, updated_at: '2020-01-24T08:00:00Z', file_sha256: expected_main_amd64_di_sha256).tap do |cf|
        cf.update! file: CarrierWaveStringFile.new(expected_main_amd64_di_content), size: expected_main_amd64_di_content.size
      end
    end

    def check_component_file(
      release_date, component_name, component_file_type, architecture_name, expected_content,
      updated: true, id_of: nil
    )
      component_file = distribution
        .component_files
        .with_component_name(component_name)
        .with_file_type(component_file_type)
        .with_architecture_name(architecture_name)
        .with_compression_type(nil)
        .order_updated_asc
        .last

      if expected_content.nil?
        expect(component_file).to be_nil
        return
      end

      expect(component_file).not_to be_nil

      if id_of
        expect(component_file&.id).to eq(id_of.id)
      else
        # created
        expect(component_file&.id).to be > component_file_old_main_amd64_di.id
      end

      if updated
        expect(component_file.updated_at).to eq(release_date)
      else
        expect(component_file.updated_at).not_to eq(release_date)
      end

      if expected_content == ''
        expect(component_file.size).to eq(0)
      else
        expect(expected_content).not_to include('MD5')
        component_file.file.use_file do |file_path|
          expect(File.read(file_path)).to eq(expected_content)
        end
      end
    end

    it 'generates Debian distribution and component files', :aggregate_failures do
      current_time = Time.utc(2020, 1, 25, 15, 17, 19)

      travel_to(current_time) do
        expect(Gitlab::ErrorTracking).not_to receive(:log_exception)

        initial_count = 8
        destroyed_count = 1
        created_count = 4 # main_amd64 + main_sources + empty contrib_all + empty contrib_amd64

        expect { subject }
          .to not_change { Packages::Package.count }
          .and not_change { Packages::PackageFile.count }
          .and change { distribution.reload.updated_at }.to(current_time.round)
          .and change { distribution.component_files.reset.count }.from(initial_count).to(initial_count - destroyed_count + created_count)
          .and change { component_file_old_main_amd64_di.reload.updated_at }.to(current_time.round)

        package_files = package.package_files.order(id: :asc).preload_debian_file_metadata.to_a
        expected_main_amd64_content = <<~EOF
        Package: libsample0
        Source: #{package.name}
        Version: #{package.version}
        Installed-Size: 7
        Maintainer: #{package_files[2].debian_fields['Maintainer']}
        Architecture: amd64
        Description: Some mostly empty lib
         Used in GitLab tests.
         .
         Testing another paragraph.
        Multi-Arch: same
        Homepage: #{package_files[2].debian_fields['Homepage']}
        Section: libs
        Priority: optional
        Filename: #{pool_prefix}/libsample0_1.2.3~alpha2_amd64.deb
        Size: 409600
        SHA256: #{package_files[2].file_sha256}

        Package: sample-dev
        Source: #{package.name} (#{package.version})
        Version: 1.2.3~binary
        Installed-Size: 7
        Maintainer: #{package_files[3].debian_fields['Maintainer']}
        Architecture: amd64
        Depends: libsample0 (= 1.2.3~binary)
        Description: Some mostly empty development files
         Used in GitLab tests.
         .
         Testing another paragraph.
        Multi-Arch: same
        Homepage: #{package_files[3].debian_fields['Homepage']}
        Section: libdevel
        Priority: optional
        Filename: #{pool_prefix}/sample-dev_1.2.3~binary_amd64.deb
        Size: 409600
        SHA256: #{package_files[3].file_sha256}
        EOF

        expected_main_sources_content = <<~EOF
        Package: #{package.name}
        Binary: sample-dev, libsample0, sample-udeb, sample-ddeb
        Version: #{package.version}
        Maintainer: #{package_files[1].debian_fields['Maintainer']}
        Build-Depends: debhelper-compat (= 13)
        Architecture: any
        Standards-Version: 4.5.0
        Format: 3.0 (native)
        Files:
         #{package_files[1].file_md5} #{package_files[1].size} #{package_files[1].file_name}
         #{package_files[0].file_md5} 964 #{package_files[0].file_name}
        Checksums-Sha256:
         #{package_files[1].file_sha256} #{package_files[1].size} #{package_files[1].file_name}
         #{package_files[0].file_sha256} 964 #{package_files[0].file_name}
        Checksums-Sha1:
         #{package_files[1].file_sha1} #{package_files[1].size} #{package_files[1].file_name}
         #{package_files[0].file_sha1} 964 #{package_files[0].file_name}
        Homepage: #{package_files[1].debian_fields['Homepage']}
        Section: misc
        Priority: extra
        Directory: #{pool_prefix}
        EOF

        check_component_file(current_time.round, 'main', :packages, 'all', nil)
        check_component_file(current_time.round, 'main', :packages, 'amd64', expected_main_amd64_content)
        check_component_file(current_time.round, 'main', :packages, 'arm64', nil)

        check_component_file(current_time.round, 'main', :di_packages, 'all', nil)
        check_component_file(current_time.round, 'main', :di_packages, 'amd64', expected_main_amd64_di_content, id_of: component_file_old_main_amd64_di)
        check_component_file(current_time.round, 'main', :di_packages, 'arm64', nil)

        check_component_file(current_time.round, 'main', :sources, nil, expected_main_sources_content)

        check_component_file(current_time.round, 'contrib', :packages, 'all', '')
        check_component_file(current_time.round, 'contrib', :packages, 'amd64', '')
        check_component_file(current_time.round, 'contrib', :packages, 'arm64', nil)

        check_component_file(current_time.round, 'contrib', :di_packages, 'all', '', updated: false, id_of: component_file_empty_contrib_all_di)
        check_component_file(current_time.round, 'contrib', :di_packages, 'amd64', '', id_of: component_file_empty_contrib_amd64_di)
        check_component_file(current_time.round, 'contrib', :di_packages, 'arm64', nil)

        check_component_file(current_time.round, 'contrib', :sources, nil, nil)

        expected_main_amd64_size = expected_main_amd64_content.bytesize
        expected_main_amd64_sha256 = Digest::SHA256.hexdigest(expected_main_amd64_content)

        expected_main_amd64_di_size = expected_main_amd64_di_content.length

        expected_main_sources_size = expected_main_sources_content.length
        expected_main_sources_sha256 = Digest::SHA256.hexdigest(expected_main_sources_content)

        expected_release_content = <<~EOF
        Codename: #{distribution.codename}
        Date: Sat, 25 Jan 2020 15:17:19 +0000
        Valid-Until: Mon, 27 Jan 2020 15:17:19 +0000
        Acquire-By-Hash: yes
        Architectures: all amd64 arm64
        Components: contrib main
        SHA256:
         e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855        0 contrib/binary-all/Packages
         e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855        0 contrib/debian-installer/binary-all/Packages
         e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855        0 contrib/binary-amd64/Packages
         e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855        0 contrib/debian-installer/binary-amd64/Packages
         e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855        0 contrib/binary-arm64/Packages
         e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855        0 contrib/debian-installer/binary-arm64/Packages
         e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855        0 contrib/source/Sources
         e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855        0 main/binary-all/Packages
         e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855        0 main/debian-installer/binary-all/Packages
         #{expected_main_amd64_sha256} #{expected_main_amd64_size.to_s.rjust(8)} main/binary-amd64/Packages
         #{expected_main_amd64_di_sha256} #{expected_main_amd64_di_size.to_s.rjust(8)} main/debian-installer/binary-amd64/Packages
         e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855        0 main/binary-arm64/Packages
         e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855        0 main/debian-installer/binary-arm64/Packages
         #{expected_main_sources_sha256} #{expected_main_sources_size.to_s.rjust(8)} main/source/Sources
        EOF
        expected_release_content = "Suite: #{distribution.suite}\n#{expected_release_content}" if distribution.suite

        check_release_files(expected_release_content)
      end

      create_list(:debian_package, 10, project: project, published_in: project_distribution)
      control = ActiveRecord::QueryRecorder.new { subject2 }

      create_list(:debian_package, 10, project: project, published_in: project_distribution)
      expect { subject3 }.not_to exceed_query_limit(control)
    end
  end

  context 'without components and architectures' do
    it 'generates minimal distribution', :aggregate_failures do
      travel_to(Time.utc(2020, 1, 25, 15, 17, 18, 123456)) do
        expect(Gitlab::ErrorTracking).not_to receive(:log_exception)

        expect { subject }
          .to not_change { Packages::Package.count }
          .and not_change { Packages::PackageFile.count }
          .and not_change { distribution.component_files.reset.count }

        expected_release_content = <<~EOF
        Codename: #{distribution.codename}
        Date: Sat, 25 Jan 2020 15:17:18 +0000
        Valid-Until: Mon, 27 Jan 2020 15:17:18 +0000
        Acquire-By-Hash: yes
        SHA256:
        EOF
        expected_release_content = "Suite: #{distribution.suite}\n#{expected_release_content}" if distribution.suite

        check_release_files(expected_release_content)
      end
    end
  end
end
