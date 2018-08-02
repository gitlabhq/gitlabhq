require 'spec_helper'

describe Gitlab::Ci::Parsers::JunitParser do
  describe '#initialize' do
    context 'when xml data is given' do
      let(:data) do
        <<-EOF.strip_heredoc
          <testsuite></testsuite>
        EOF
      end

      let(:parser) { described_class.new(data) }

      it 'initialize Hash from the given data' do
        expect { parser }.not_to raise_error

        expect(parser.data).to be_a(Hash)
      end
    end

    context 'when json data is given' do
      let(:data) { { testsuite: 'abc' }.to_json }

      it 'raises an error' do
        expect { described_class.new(data) }.to raise_error(described_class::JunitParserError)
      end
    end
  end

  describe '#parse!' do
    subject { described_class.new(junit).parse!(test_suite) }

    let(:test_suite) { Gitlab::Ci::Reports::TestSuite.new('rspec') }
    let(:test_cases) { flattened_test_cases(test_suite) }

    context 'when XML is formated as JUnit' do
      context 'when there are no test cases' do
        let(:junit) do
          <<-EOF.strip_heredoc
            <testsuite></testsuite>
          EOF
        end

        it 'raises an error and does not add any test cases' do
          expect { subject }.to raise_error(described_class::JunitParserError)

          expect(test_cases.count).to eq(0)
        end
      end

      context 'when there is a test case' do
        let(:junit) do
          <<-EOF.strip_heredoc
            <testsuite>
              <testcase classname='Calculator' name='sumTest1' time='0.01'></testcase>
            </testsuite>
          EOF
        end

        it 'parses XML and adds a test case to a suite' do
          expect { subject }.not_to raise_error

          expect(test_cases[0].classname).to eq('Calculator')
          expect(test_cases[0].name).to eq('sumTest1')
          expect(test_cases[0].execution_time).to eq(0.01)
        end
      end

      context 'when there are two test cases' do
        let(:junit) do
          <<-EOF.strip_heredoc
            <testsuite>
              <testcase classname='Calculator' name='sumTest1' time='0.01'></testcase>
              <testcase classname='Calculator' name='sumTest2' time='0.02'></testcase>
            </testsuite>
          EOF
        end

        it 'parses XML and adds test cases to a suite' do
          expect { subject }.not_to raise_error

          expect(test_cases[0].classname).to eq('Calculator')
          expect(test_cases[0].name).to eq('sumTest1')
          expect(test_cases[0].execution_time).to eq(0.01)
          expect(test_cases[1].classname).to eq('Calculator')
          expect(test_cases[1].name).to eq('sumTest2')
          expect(test_cases[1].execution_time).to eq(0.02)
        end
      end

      context 'when there are two test suites' do
        let(:junit) do
          <<-EOF.strip_heredoc
            <testsuites>
              <testsuite>
                <testcase classname='Calculator' name='sumTest1' time='0.01'></testcase>
                <testcase classname='Calculator' name='sumTest2' time='0.02'></testcase>
              </testsuite>
              <testsuite>
                <testcase classname='Statemachine' name='happy path' time='100'></testcase>
                <testcase classname='Statemachine' name='unhappy path' time='200'></testcase>
              </testsuite>
            </testsuites>
          EOF
        end

        it 'parses XML and adds test cases to a suite' do
          expect { subject }.not_to raise_error

          expect(test_cases[0].classname).to eq('Calculator')
          expect(test_cases[0].name).to eq('sumTest1')
          expect(test_cases[0].execution_time).to eq(0.01)
          expect(test_cases[1].classname).to eq('Calculator')
          expect(test_cases[1].name).to eq('sumTest2')
          expect(test_cases[1].execution_time).to eq(0.02)
          expect(test_cases[2].classname).to eq('Statemachine')
          expect(test_cases[2].name).to eq('happy path')
          expect(test_cases[2].execution_time).to eq(100)
          expect(test_cases[3].classname).to eq('Statemachine')
          expect(test_cases[3].name).to eq('unhappy path')
          expect(test_cases[3].execution_time).to eq(200)
        end
      end
    end

    def flattened_test_cases(test_suite)
      test_suite.test_cases.map do |status, value|
        value.map do |key, test_case|
          test_case
        end
      end.flatten
    end
  end
end
