require 'rails_helper'

describe RegexpValidator do
  let(:project) { build(:project) }

  it 'does not add an error if attribute is nil' do
    validate_regexp(project, :auto_protected_branch_pattern, nil)

    expect(project.errors[:auto_protected_branch_pattern]).to be_empty
  end

  it 'does not add an error if attribute is ""' do
    validate_regexp(project, :auto_protected_branch_pattern, '')

    expect(project.errors[:auto_protected_branch_pattern]).to be_empty
  end

  it 'does not add an error if attribute is a valid regex' do
    validate_regexp(project, :auto_protected_branch_pattern, '[0-9]')

    expect(project.errors[:auto_protected_branch_pattern]).to be_empty
  end

  it 'adds an error if attribute is not a valid regex' do
    validate_regexp(project, :auto_protected_branch_pattern, '[0-9')

    expect(project.errors[:auto_protected_branch_pattern].size).to eq(1)
    expect(project.errors[:auto_protected_branch_pattern].first).to eq("'[0-9' is not a valid regular expression: premature end of char-class: /[0-9/")
  end

  def validate_regexp(record, attribute, value)
    RegexpValidator.new(attributes: attribute).validate_each(record, attribute, value)
  end
end
