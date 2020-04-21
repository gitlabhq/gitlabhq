# frozen_string_literal: true

require 'spec_helper'

describe UserTypeEnums do
  it '.types' do
    expect(described_class.types.keys).to include('alert_bot', 'project_bot', 'human', 'ghost')
  end

  it '.bots' do
    expect(described_class.bots.keys).to include('alert_bot', 'project_bot')
  end
end
