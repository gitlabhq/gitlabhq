require 'spec_helper'
require Rails.root.join('db', 'migrate', '20180531220618_change_default_value_for_dsa_key_restriction.rb')

describe ChangeDefaultValueForDsaKeyRestriction, :migration do
  let(:application_settings) { table(:application_settings) }

  before do
    application_settings.create!
  end

  it 'changes the default value for dsa_key_restriction' do
    expect(application_settings.first.dsa_key_restriction).to eq(0)

    migrate!

    application_settings.reset_column_information
    new_setting = application_settings.create!

    expect(application_settings.count).to eq(2)
    expect(new_setting.dsa_key_restriction).to eq(-1)
  end

  it 'changes the existing setting' do
    setting = application_settings.last

    expect(setting.dsa_key_restriction).to eq(0)

    migrate!

    expect(application_settings.count).to eq(1)
    expect(setting.reload.dsa_key_restriction).to eq(-1)
  end
end
