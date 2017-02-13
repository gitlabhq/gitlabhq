require 'spec_helper'

describe SystemCheck, lib: true do
  subject { SystemCheck }

  describe '.run' do
    it 'requires custom executor to be a BasicExecutor' do
      expect { subject.run('Component', [], SystemCheck::SimpleExecutor) }.not_to raise_error
    end

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
