# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe MigrateApplicationSettingsHelpText, feature_category: :database do
  let(:application_settings_table) { table(:application_settings) }
  let(:appearances_table) { table(:appearances) }

  let!(:application_settings) do
    application_settings_table.create!(sign_in_text: 'and sign in', help_text: 'help text to append')
  end

  let!(:description_html) { '<p>some description</p>' }
  let!(:appearances) do
    appearances_table.create!(title: 'title', description: 'some description', description_html: description_html)
  end

  it 'appends text from application_settings correctly' do
    expect { migrate! }.to change { appearances.reload.description }.from('some description')
      .to("some description\n\nand sign in\n\nhelp text to append")

    expect(appearances.description_html).to be_nil
    expect(application_settings.reload.sign_in_text).to eq('')
    expect(application_settings.reload.help_text).to eq('')
  end

  it 'when description is empty, appends text from application_settings text correctly' do
    appearances_table.update!(description: '')
    expect { migrate! }.to change { appearances.reload.description }.from('')
      .to("and sign in\n\nhelp text to append")

    expect(appearances.description_html).to be_nil
    expect(application_settings.reload.sign_in_text).to eq('')
    expect(application_settings.reload.help_text).to eq('')
  end

  it 'when description and help_text are empty, appends text from application_settings correctly' do
    appearances_table.update!(description: '')
    application_settings_table.update!(help_text: '')
    expect { migrate! }.to change { appearances.reload.description }.from('')
      .to("and sign in")

    expect(appearances.description_html).to be_nil
    expect(application_settings.reload.sign_in_text).to eq('')
    expect(application_settings.reload.help_text).to eq('')
  end

  it 'does not appends anything if the fields are empty' do
    application_settings_table.update!(sign_in_text: nil, help_text: nil)

    expect { migrate! }.not_to change { appearances.reload.description }.from('some description')

    expect(appearances.description_html).to eq(description_html)
  end

  it 'logs error when there are more than 1 ApplicationSettings records' do
    application_settings_table.create!

    expect { migrate! }.not_to change { appearances.description }.from('some description')
  end
end
