# frozen_string_literal: true

RSpec.shared_examples 'updating the namespace package setting attributes' do |from: {}, to:|
  it_behaves_like 'not creating the namespace package setting'

  it 'updates the namespace package setting' do
    expect { subject }
      .to change { namespace.package_settings.reload.maven_duplicates_allowed }.from(from[:maven_duplicates_allowed]).to(to[:maven_duplicates_allowed])
      .and change { namespace.package_settings.reload.maven_duplicate_exception_regex }.from(from[:maven_duplicate_exception_regex]).to(to[:maven_duplicate_exception_regex])
      .and change { namespace.package_settings.reload.generic_duplicates_allowed }.from(from[:generic_duplicates_allowed]).to(to[:generic_duplicates_allowed])
      .and change { namespace.package_settings.reload.generic_duplicate_exception_regex }.from(from[:generic_duplicate_exception_regex]).to(to[:generic_duplicate_exception_regex])
  end
end

RSpec.shared_examples 'not creating the namespace package setting' do
  it "doesn't create the namespace package setting" do
    expect { subject }.not_to change { Namespace::PackageSetting.count }
  end
end

RSpec.shared_examples 'creating the namespace package setting' do
  it 'creates a new package setting' do
    expect { subject }.to change { Namespace::PackageSetting.count }.by(1)
  end

  it 'saves the settings', :aggregate_failures do
    subject

    expect(namespace.package_setting_relation.maven_duplicates_allowed).to eq(package_settings[:maven_duplicates_allowed])
    expect(namespace.package_setting_relation.maven_duplicate_exception_regex).to eq(package_settings[:maven_duplicate_exception_regex])
    expect(namespace.package_setting_relation.generic_duplicates_allowed).to eq(package_settings[:generic_duplicates_allowed])
    expect(namespace.package_setting_relation.generic_duplicate_exception_regex).to eq(package_settings[:generic_duplicate_exception_regex])
  end

  it_behaves_like 'returning a success'
end
