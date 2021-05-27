# frozen_string_literal: true

RSpec.shared_examples 'a package detail' do
  it_behaves_like 'a working graphql query' do
    it 'matches the JSON schema' do
      expect(package_details).to match_schema('graphql/packages/package_details')
    end
  end
end

RSpec.shared_examples 'a package with files' do
  it 'has the right amount of files' do
    expect(package_files_response.length).to be(package.package_files.length)
  end

  it 'has the basic package files data' do
    expect(first_file_response).to include(
      'id' => global_id_of(first_file),
      'fileName' => first_file.file_name,
      'size' => first_file.size.to_s,
      'downloadPath' => first_file.download_path,
      'fileSha1' => first_file.file_sha1,
      'fileMd5' => first_file.file_md5,
      'fileSha256' => first_file.file_sha256
    )
  end
end
