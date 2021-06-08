# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemCheck, :silence_stdout do
  before do
    stub_const('SimpleCheck', Class.new(SystemCheck::BaseCheck))
    stub_const('OtherCheck', Class.new(SystemCheck::BaseCheck))

    SimpleCheck.class_eval do
      def check?
        true
      end
    end

    OtherCheck.class_eval do
      def check?
        false
      end
    end
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
