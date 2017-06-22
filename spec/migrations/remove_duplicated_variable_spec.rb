require 'spec_helper'
require Rails.root.join('db', 'migrate', '20170622135451_remove_duplicated_variable.rb')

describe RemoveDuplicatedVariable, :migration do
  let(:variables) { table(:ci_variables) }
  let(:projects) { table(:projects) }

  before do
    projects.create!(id: 1)
    variables.create!(id: 1, key: 'key1', project_id: 1)
    variables.create!(id: 2, key: 'key2', project_id: 1)
    variables.create!(id: 3, key: 'keyX', project_id: 1)
    variables.create!(id: 4, key: 'keyX', project_id: 1)
    variables.create!(id: 5, key: 'keyY', project_id: 1)
    variables.create!(id: 6, key: 'keyX', project_id: 1)
    variables.create!(id: 7, key: 'key7', project_id: 1)
    variables.create!(id: 8, key: 'keyY', project_id: 1)
  end

  it 'correctly remove duplicated records with smaller id' do
    migrate!

    expect(variables.pluck(:id)).to contain_exactly(1, 2, 6, 7, 8)
  end
end
