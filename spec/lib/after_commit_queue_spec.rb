require 'spec_helper'

describe AfterCommitQueue do
  it 'runs after transaction is committed' do
    called = false
    test_proc = proc { called = true }

    project = build(:project)
    project.run_after_commit(&test_proc)

    project.save

    expect(called).to be true
  end
end
