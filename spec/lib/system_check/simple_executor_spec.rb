# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemCheck::SimpleExecutor, :silence_stdout do
  before do
    stub_const('SimpleCheck', Class.new(SystemCheck::BaseCheck))
    stub_const('OtherCheck', Class.new(SystemCheck::BaseCheck))
    stub_const('SkipCheck', Class.new(SystemCheck::BaseCheck))
    stub_const('DynamicSkipCheck', Class.new(SystemCheck::BaseCheck))
    stub_const('MultiCheck', Class.new(SystemCheck::BaseCheck))
    stub_const('SkipMultiCheck', Class.new(SystemCheck::BaseCheck))
    stub_const('RepairCheck', Class.new(SystemCheck::BaseCheck))
    stub_const('BugousCheck', Class.new(SystemCheck::BaseCheck))

    SimpleCheck.class_eval do
      set_name 'my simple check'

      def check?
        true
      end
    end

    OtherCheck.class_eval do
      set_name 'other check'

      def check?
        false
      end

      def show_error
        $stdout.puts 'this is an error text'
      end
    end

    SkipCheck.class_eval do
      set_name 'skip check'
      set_skip_reason 'this is a skip reason'

      def skip?
        true
      end

      def check?
        raise 'should not execute this'
      end
    end

    DynamicSkipCheck.class_eval do
      set_name 'dynamic skip check'
      set_skip_reason 'this is a skip reason'

      def skip?
        self.skip_reason = 'this is a dynamic skip reason'
        true
      end

      def check?
        raise 'should not execute this'
      end
    end

    MultiCheck.class_eval do
      set_name 'multi check'

      def multi_check
        $stdout.puts 'this is a multi output check'
      end

      def check?
        raise 'should not execute this'
      end
    end

    SkipMultiCheck.class_eval do
      set_name 'skip multi check'

      def skip?
        true
      end

      def multi_check
        raise 'should not execute this'
      end
    end

    RepairCheck.class_eval do
      set_name 'repair check'

      def check?
        false
      end

      def repair!
        true
      end

      def show_error
        $stdout.puts 'this is an error message'
      end
    end

    BugousCheck.class_eval do
      set_name 'my bugous check'

      def check?
        raise StandardError, 'omg'
      end
    end
  end

  describe '#component' do
    it 'returns stored component name' do
      expect(subject.component).to eq('Test')
    end
  end

  describe '#checks' do
    before do
      subject << SimpleCheck
    end

    it 'returns a set of classes' do
      expect(subject.checks).to include(SimpleCheck)
    end
  end

  describe '#<<' do
    before do
      subject << SimpleCheck
    end

    it 'appends a new check to the Set' do
      subject << OtherCheck
      stored_checks = subject.checks.to_a

      expect(stored_checks.first).to eq(SimpleCheck)
      expect(stored_checks.last).to eq(OtherCheck)
    end

    it 'inserts unique itens only' do
      subject << SimpleCheck

      expect(subject.checks.size).to eq(1)
    end

    it 'errors out when passing multiple items' do
      expect { subject << [SimpleCheck, OtherCheck] }.to raise_error(ArgumentError)
    end
  end

  subject { described_class.new('Test') }

  describe '#execute' do
    before do
      subject << SimpleCheck
      subject << OtherCheck
    end

    it 'runs included checks' do
      expect(subject).to receive(:run_check).with(SimpleCheck)
      expect(subject).to receive(:run_check).with(OtherCheck)

      subject.execute
    end
  end

  describe '#run_check' do
    it 'prints check name' do
      expect(SimpleCheck).to receive(:display_name).and_call_original
      expect { subject.run_check(SimpleCheck) }.to output(/my simple check/).to_stdout
    end

    context 'when check pass' do
      it 'prints yes' do
        expect_any_instance_of(SimpleCheck).to receive(:check?).and_call_original
        expect { subject.run_check(SimpleCheck) }.to output(/ \.\.\. yes/).to_stdout
      end
    end

    context 'when check fails' do
      it 'prints no' do
        expect_any_instance_of(OtherCheck).to receive(:check?).and_call_original
        expect { subject.run_check(OtherCheck) }.to output(/ \.\.\. no/).to_stdout
      end

      it 'displays error message from #show_error' do
        expect_any_instance_of(OtherCheck).to receive(:show_error).and_call_original
        expect { subject.run_check(OtherCheck) }.to output(/this is an error text/).to_stdout
      end

      context 'when check implements #repair!' do
        it 'executes #repair!' do
          expect_any_instance_of(RepairCheck).to receive(:repair!)

          subject.run_check(RepairCheck)
        end

        context 'when repair succeeds' do
          it 'does not execute #show_error' do
            expect_any_instance_of(RepairCheck).to receive(:repair!).and_call_original
            expect_any_instance_of(RepairCheck).not_to receive(:show_error)

            subject.run_check(RepairCheck)
          end
        end

        context 'when repair fails' do
          it 'does not execute #show_error' do
            expect_any_instance_of(RepairCheck).to receive(:repair!) { false }
            expect_any_instance_of(RepairCheck).to receive(:show_error)

            subject.run_check(RepairCheck)
          end
        end
      end
    end

    context 'when check implements skip?' do
      it 'executes #skip? method' do
        expect_any_instance_of(SkipCheck).to receive(:skip?).and_call_original

        subject.run_check(SkipCheck)
      end

      it 'displays .skip_reason' do
        expect { subject.run_check(SkipCheck) }.to output(/this is a skip reason/).to_stdout
      end

      it 'displays #skip_reason' do
        expect { subject.run_check(DynamicSkipCheck) }.to output(/this is a dynamic skip reason/).to_stdout
      end

      it 'does not execute #check when #skip? is true' do
        expect_any_instance_of(SkipCheck).not_to receive(:check?)

        subject.run_check(SkipCheck)
      end
    end

    context 'when implements a #multi_check' do
      it 'executes #multi_check method' do
        expect_any_instance_of(MultiCheck).to receive(:multi_check)

        subject.run_check(MultiCheck)
      end

      it 'does not execute #check method' do
        expect_any_instance_of(MultiCheck).not_to receive(:check)

        subject.run_check(MultiCheck)
      end

      context 'when check implements #skip?' do
        it 'executes #skip? method' do
          expect_any_instance_of(SkipMultiCheck).to receive(:skip?).and_call_original

          subject.run_check(SkipMultiCheck)
        end
      end
    end

    context 'when there is an exception' do
      it 'rescues the exception' do
        expect { subject.run_check(BugousCheck) }.not_to raise_exception
      end
    end
  end
end
