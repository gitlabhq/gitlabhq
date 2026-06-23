# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::Packages::Maven, feature_category: :package_registry do
  let(:helper) do
    Class.new do
      include API::Helpers::Packages::Maven
    end.new
  end

  describe '#extract_maven_package_name_and_version' do
    using RSpec::Parameterized::TableSyntax

    subject { helper.extract_maven_package_name_and_version(path, file_name) }

    # The last path segment is the version for everything except a versionless
    # maven-metadata.xml (and its checksums), where the whole path is the name.
    where(:path, :file_name, :expected_name, :expected_version) do
      'com/example/my-app/1.0.0'        | 'my-app-1.0.0.jar'        | 'com/example/my-app' | '1.0.0'
      'com/example/my-app/1.0.0'        | 'my-app-1.0.0.pom'        | 'com/example/my-app' | '1.0.0'
      'com/example/my-app'              | 'maven-metadata.xml'      | 'com/example/my-app' | nil
      'com/example/my-app'              | 'maven-metadata.xml.sha1' | 'com/example/my-app' | nil
      'com/example/my-app'              | 'maven-metadata.xml.md5'  | 'com/example/my-app' | nil
      'com/example/my-app/1.0-SNAPSHOT' | 'maven-metadata.xml'      | 'com/example/my-app' | '1.0-SNAPSHOT'
      'com/example/my-app/1.0-SNAPSHOT' | 'maven-metadata.xml.sha1' | 'com/example/my-app' | '1.0-SNAPSHOT'
    end

    with_them do
      it { is_expected.to eq([expected_name, expected_version]) }
    end
  end
end
