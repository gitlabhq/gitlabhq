require 'rake_helper'
Rake.application.rake_require 'tasks/config_lint'

describe ConfigLint do
  let(:files) { ['lib/support/fake.sh'] }

  it 'errors out if any bash scripts have errors' do
    expect { described_class.run(files) { system('exit 1') } }.to raise_error(SystemExit)
  end

  it 'passes if all scripts are fine' do
    expect { described_class.run(files) { system('exit 0') } }.not_to raise_error
  end
end

describe 'config_lint rake task' do
  before do
    # Prevent `system` from actually being called
    allow(Kernel).to receive(:system).and_return(true)
  end

  it 'runs lint on shell scripts' do
    expect(Kernel).to receive(:system).with('bash', '-n', 'lib/support/init.d/gitlab')

    run_rake_task('config_lint')
  end
end
