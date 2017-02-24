require 'spec_helper'

describe ChatSlashCommandsService, models: true do
  it 'returns placeholder in fields' do
    service = ChatSlashCommandsService.new()

    expect(service[:fields][0][:autocomplete]).to eq 'off'
  end
end
