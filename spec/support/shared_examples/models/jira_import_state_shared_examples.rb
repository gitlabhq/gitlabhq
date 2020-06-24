# frozen_string_literal: true

RSpec.shared_examples 'multiple running imports not allowed' do
  it 'returns not valid' do
    new_import = build(:jira_import_state, project: project)

    expect(new_import).not_to be_valid
    expect(new_import.errors[:project]).not_to be_nil
  end
end

RSpec.shared_examples 'in progress' do |status|
  it 'returns true' do
    jira_import_state = build(:jira_import_state, status: status)
    expect(jira_import_state).to be_in_progress
  end
end

RSpec.shared_examples 'not in progress' do |status|
  it 'returns false' do
    jira_import_state = build(:jira_import_state, status: status)
    expect(jira_import_state).not_to be_in_progress
  end
end

RSpec.shared_examples 'can transition' do |states|
  states.each do |state|
    it 'returns true' do
      expect(jira_import.send(state)).to be true
    end
  end
end

RSpec.shared_examples 'cannot transition' do |states|
  states.each do |state|
    it 'returns false' do
      expect(jira_import.send(state)).to be false
    end
  end
end
