require 'spec_helper'
require 'rake_helper'

describe SystemCheck do
  class SimpleCheck < SystemCheck::BaseCheck
    def check?
      true
    end
  end

  class OtherCheck < SystemCheck::BaseCheck
    def check?
      false
    end
  end

  before do
    silence_output
  end

  describe '.run' do
    subject { described_class }

    it 'detects execution of SimpleCheck' do
      is_expected.to execute_check(SimpleCheck)

      subject.run('Test', [SimpleCheck])
    end

    it 'detects exclusion of OtherCheck in execution' do
      is_expected.not_to execute_check(OtherCheck)

      subject.run('Test', [SimpleCheck])
    end
  end
end
