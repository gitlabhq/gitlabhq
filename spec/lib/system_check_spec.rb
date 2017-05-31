require 'spec_helper'
require 'rake_helper'

describe SystemCheck, lib: true do
  subject { SystemCheck }

  before do
    silence_output
  end

  describe '.run' do
    context 'custom matcher' do
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

      subject { SystemCheck }

      it 'detects execution of SimpleCheck' do
        is_expected.to execute_check(SimpleCheck)

        SystemCheck.run('Test', [SimpleCheck])
      end

      it 'detects exclusion of OtherCheck in execution' do
        is_expected.not_to execute_check(OtherCheck)

        SystemCheck.run('Test', [SimpleCheck])
      end
    end
  end
end
