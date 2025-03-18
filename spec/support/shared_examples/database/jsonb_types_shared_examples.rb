# frozen_string_literal: true

RSpec.shared_examples 'validates jsonb integer field' do |field, settings_attribute|
  it { is_expected.to allow_value({ field => 0 }).for(settings_attribute) }
  it { is_expected.to allow_value({ field => 100 }).for(settings_attribute) }
  it { is_expected.to allow_value({ field => 9999999 }).for(settings_attribute) }
  it { is_expected.not_to allow_value({ field => "string" }).for(settings_attribute) }
  it { is_expected.not_to allow_value({ field => true }).for(settings_attribute) }
  it { is_expected.not_to allow_value({ field => nil }).for(settings_attribute) }
  it { is_expected.not_to allow_value({ field => 1.5 }).for(settings_attribute) }
end

RSpec.shared_examples 'validates jsonb boolean field' do |field, settings_attribute|
  it { is_expected.to allow_value({ field => true }).for(settings_attribute) }
  it { is_expected.to allow_value({ field => false }).for(settings_attribute) }
  it { is_expected.not_to allow_value({ field => "true" }).for(settings_attribute) }
  it { is_expected.not_to allow_value({ field => 1 }).for(settings_attribute) }
  it { is_expected.not_to allow_value({ field => nil }).for(settings_attribute) }
  it { is_expected.not_to allow_value({ field => "false" }).for(settings_attribute) }
  it { is_expected.not_to allow_value({ field => 0 }).for(settings_attribute) }
end
