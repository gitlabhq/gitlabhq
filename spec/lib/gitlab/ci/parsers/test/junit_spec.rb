# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::Ci::Parsers::Test::Junit do
  describe '#parse!' do
    subject { described_class.new.parse!(junit, test_suite) }

    let(:test_suite) { Gitlab::Ci::Reports::TestSuite.new('rspec') }
    let(:test_cases) { flattened_test_cases(test_suite) }

    context 'when data is JUnit style XML' do
      context 'when there are no <testcases> in <testsuite>' do
        let(:junit) do
          <<-EOF.strip_heredoc
            <testsuite></testsuite>
          EOF
        end

        it 'ignores the case' do
          expect { subject }.not_to raise_error

          expect(test_cases.count).to eq(0)
        end
      end

      context 'when there are no <testcases> in <testsuites>' do
        let(:junit) do
          <<-EOF.strip_heredoc
            <testsuites><testsuite /></testsuites>
          EOF
        end

        it 'ignores the case' do
          expect { subject }.not_to raise_error

          expect(test_cases.count).to eq(0)
        end
      end

      context 'when there is only one <testsuite> in <testsuites>' do
        let(:junit) do
          <<-EOF.strip_heredoc
            <testsuites>
              <testsuite>
                <testcase classname='Calculator' name='sumTest1' time='0.01'></testcase>
              </testsuite>
            </testsuites>
          EOF
        end

        it 'parses XML and adds a test case to a suite' do
          expect { subject }.not_to raise_error

          expect(test_cases[0].classname).to eq('Calculator')
          expect(test_cases[0].name).to eq('sumTest1')
          expect(test_cases[0].execution_time).to eq(0.01)
        end
      end

      context 'when there is <testcase>' do
        let(:junit) do
          <<-EOF.strip_heredoc
              <testsuite>
                <testcase classname='Calculator' name='sumTest1' time='0.01'>
                  #{testcase_content}
                </testcase>
              </testsuite>
          EOF
        end

        let(:test_case) { test_cases[0] }

        before do
          expect { subject }.not_to raise_error
        end

        shared_examples_for '<testcase> XML parser' do |status, output|
          it 'parses XML and adds a test case to the suite' do
            aggregate_failures do
              expect(test_case.classname).to eq('Calculator')
              expect(test_case.name).to eq('sumTest1')
              expect(test_case.execution_time).to eq(0.01)
              expect(test_case.status).to eq(status)
              expect(test_case.system_output).to eq(output)
            end
          end
        end

        context 'and has failure' do
          let(:testcase_content) { '<failure>Some failure</failure>' }

          it_behaves_like '<testcase> XML parser',
            ::Gitlab::Ci::Reports::TestCase::STATUS_FAILED,
            'Some failure'
        end

        context 'and has error' do
          let(:testcase_content) { '<error>Some error</error>' }

          it_behaves_like '<testcase> XML parser',
            ::Gitlab::Ci::Reports::TestCase::STATUS_ERROR,
            'Some error'
        end

        context 'and has an unknown type' do
          let(:testcase_content) { '<foo>Some foo</foo>' }

          it_behaves_like '<testcase> XML parser',
            ::Gitlab::Ci::Reports::TestCase::STATUS_SUCCESS,
            nil
        end

        context 'and has no content' do
          let(:testcase_content) { '' }

          it_behaves_like '<testcase> XML parser',
            ::Gitlab::Ci::Reports::TestCase::STATUS_SUCCESS,
            nil
        end
      end

      context 'PHPUnit' do
        let(:junit) do
          <<-EOF.strip_heredoc
          <testsuites>
            <testsuite name="Project Test Suite" tests="1" assertions="1" failures="0" errors="0" time="1.376748">
              <testsuite name="XXX\\FrontEnd\\WebBundle\\Tests\\Controller\\LogControllerTest" file="/Users/mcfedr/projects/xxx/server/tests/XXX/FrontEnd/WebBundle/Tests/Controller/LogControllerTest.php" tests="1" assertions="1" failures="0" errors="0" time="1.376748">
                <testcase name="testIndexAction" class="XXX\\FrontEnd\\WebBundle\\Tests\\Controller\\LogControllerTest" file="/Users/mcfedr/projects/xxx/server/tests/XXX/FrontEnd/WebBundle/Tests/Controller/LogControllerTest.php" line="9" assertions="1" time="1.376748"/>
              </testsuite>
            </testsuite>
          </testsuites>
          EOF
        end

        it 'parses XML and adds a test case to a suite' do
          expect { subject }.not_to raise_error

          expect(test_cases.count).to eq(1)
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

    context 'when data is not JUnit style XML' do
      let(:junit) { { testsuite: 'abc' }.to_json }

      it 'raises an error' do
        expect { subject }.to raise_error(described_class::JunitParserError)
      end
    end

    private

    def flattened_test_cases(test_suite)
      test_suite.test_cases.map do |status, value|
        value.map do |key, test_case|
          test_case
        end
      end.flatten
    end
  end
end
