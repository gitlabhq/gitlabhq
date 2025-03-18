# frozen_string_literal: true

RSpec.shared_examples 'updating the namespace package setting attributes' do |to:, from: {}|
  it_behaves_like 'not creating the namespace package setting'

  it 'updates the namespace package setting' do
    expect { subject }
      .to change { namespace.package_settings.reset.attributes.symbolize_keys.slice(*from.keys) }
      .from(from).to(to)
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

    expect(namespace.package_setting_relation).to have_attributes(
      maven_duplicates_allowed: package_settings[:maven_duplicates_allowed],
      maven_duplicate_exception_regex: package_settings[:maven_duplicate_exception_regex],
      generic_duplicates_allowed: package_settings[:generic_duplicates_allowed],
      generic_duplicate_exception_regex: package_settings[:generic_duplicate_exception_regex],
      nuget_duplicates_allowed: package_settings[:nuget_duplicates_allowed],
      nuget_duplicate_exception_regex: package_settings[:nuget_duplicate_exception_regex],
      nuget_symbol_server_enabled: package_settings[:nuget_symbol_server_enabled],
      terraform_module_duplicates_allowed: package_settings[:terraform_module_duplicates_allowed],
      terraform_module_duplicate_exception_regex: package_settings[:terraform_module_duplicate_exception_regex],
      audit_events_enabled: package_settings[:audit_events_enabled]
    )
  end

  it_behaves_like 'returning a success'
end
