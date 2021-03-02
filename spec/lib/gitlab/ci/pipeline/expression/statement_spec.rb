# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Expression::Statement do
  let(:variables) do
    Gitlab::Ci::Variables::Collection.new
      .append(key: 'PRESENT_VARIABLE', value: 'my variable')
      .append(key: 'PATH_VARIABLE', value: 'a/path/variable/value')
      .append(key: 'FULL_PATH_VARIABLE', value: '/a/full/path/variable/value')
      .append(key: 'EMPTY_VARIABLE', value: '')
  end

  subject do
    described_class.new(text, variables)
  end

  describe '.new' do
    context 'when variables are not provided' do
      it 'allows to properly initializes the statement' do
        statement = described_class.new('$PRESENT_VARIABLE')

        expect(statement.evaluate).to be_nil
      end
    end
  end

  describe '#evaluate' do
    using RSpec::Parameterized::TableSyntax

    where(:expression, :value) do
      '$PRESENT_VARIABLE == "my variable"'                          | true
      '"my variable" == $PRESENT_VARIABLE'                          | true
      '$PRESENT_VARIABLE == null'                                   | false
      '$EMPTY_VARIABLE == null'                                     | false
      '"" == $EMPTY_VARIABLE'                                       | true
      '$EMPTY_VARIABLE'                                             | ''
      '$UNDEFINED_VARIABLE == null'                                 | true
      'null == $UNDEFINED_VARIABLE'                                 | true
      '$PRESENT_VARIABLE'                                           | 'my variable'
      '$UNDEFINED_VARIABLE'                                         | nil
      "$PRESENT_VARIABLE =~ /var.*e$/"                              | true
      '$PRESENT_VARIABLE =~ /va\r.*e$/'                             | false
      '$PRESENT_VARIABLE =~ /va\/r.*e$/'                            | false
      "$PRESENT_VARIABLE =~ /var.*e$/"                              | true
      "$PRESENT_VARIABLE =~ /^var.*/"                               | false
      "$EMPTY_VARIABLE =~ /var.*/"                                  | false
      "$UNDEFINED_VARIABLE =~ /var.*/"                              | false
      "$PRESENT_VARIABLE =~ /VAR.*/i"                               | true
      '$PATH_VARIABLE =~ /path\/variable/'                          | true
      '$FULL_PATH_VARIABLE =~ /^\/a\/full\/path\/variable\/value$/' | true
      '$FULL_PATH_VARIABLE =~ /\\/path\\/variable\\/value$/'        | true
      '$PRESENT_VARIABLE != "my variable"'                          | false
      '"my variable" != $PRESENT_VARIABLE'                          | false
      '$PRESENT_VARIABLE != null'                                   | true
      '$EMPTY_VARIABLE != null'                                     | true
      '"" != $EMPTY_VARIABLE'                                       | false
      '$UNDEFINED_VARIABLE != null'                                 | false
      'null != $UNDEFINED_VARIABLE'                                 | false
      "$PRESENT_VARIABLE !~ /var.*e$/"                              | false
      "$PRESENT_VARIABLE !~ /^var.*/"                               | true
      '$PRESENT_VARIABLE !~ /^v\ar.*/'                              | true
      '$PRESENT_VARIABLE !~ /^v\/ar.*/'                             | true
      "$EMPTY_VARIABLE !~ /var.*/"                                  | true
      "$UNDEFINED_VARIABLE !~ /var.*/"                              | true
      "$PRESENT_VARIABLE !~ /VAR.*/i"                               | false

      '$PRESENT_VARIABLE && "string"'          | 'string'
      '$PRESENT_VARIABLE && $PRESENT_VARIABLE' | 'my variable'
      '$PRESENT_VARIABLE && $EMPTY_VARIABLE'   | ''
      '$PRESENT_VARIABLE && null'              | nil
      '"string" && $PRESENT_VARIABLE'          | 'my variable'
      '$EMPTY_VARIABLE && $PRESENT_VARIABLE'   | 'my variable'
      'null && $PRESENT_VARIABLE'              | nil
      '$EMPTY_VARIABLE && "string"'            | 'string'
      '$EMPTY_VARIABLE && $EMPTY_VARIABLE'     | ''
      '"string" && $EMPTY_VARIABLE'            | ''
      '"string" && null'                       | nil
      'null && "string"'                       | nil
      '"string" && "string"'                   | 'string'
      'null && null'                           | nil

      '$PRESENT_VARIABLE =~ /my var/ && $EMPTY_VARIABLE =~ /nope/' | false
      '$EMPTY_VARIABLE == "" && $PRESENT_VARIABLE'                 | 'my variable'
      '$EMPTY_VARIABLE == "" && $PRESENT_VARIABLE != "nope"'       | true
      '$PRESENT_VARIABLE && $EMPTY_VARIABLE'                       | ''
      '$PRESENT_VARIABLE && $UNDEFINED_VARIABLE'                   | nil
      '$UNDEFINED_VARIABLE && $EMPTY_VARIABLE'                     | nil
      '$UNDEFINED_VARIABLE && $PRESENT_VARIABLE'                   | nil

      '$FULL_PATH_VARIABLE =~ /^\/a\/full\/path\/variable\/value$/ && $PATH_VARIABLE =~ /path\/variable/'      | true
      '$FULL_PATH_VARIABLE =~ /^\/a\/bad\/path\/variable\/value$/ && $PATH_VARIABLE =~ /path\/variable/'       | false
      '$FULL_PATH_VARIABLE =~ /^\/a\/full\/path\/variable\/value$/ && $PATH_VARIABLE =~ /bad\/path\/variable/' | false
      '$FULL_PATH_VARIABLE =~ /^\/a\/bad\/path\/variable\/value$/ && $PATH_VARIABLE =~ /bad\/path\/variable/'  | false

      '$FULL_PATH_VARIABLE =~ /^\/a\/full\/path\/variable\/value$/ || $PATH_VARIABLE =~ /path\/variable/'      | true
      '$FULL_PATH_VARIABLE =~ /^\/a\/bad\/path\/variable\/value$/ || $PATH_VARIABLE =~ /path\/variable/'       | true
      '$FULL_PATH_VARIABLE =~ /^\/a\/full\/path\/variable\/value$/ || $PATH_VARIABLE =~ /bad\/path\/variable/' | true
      '$FULL_PATH_VARIABLE =~ /^\/a\/bad\/path\/variable\/value$/ || $PATH_VARIABLE =~ /bad\/path\/variable/'  | false

      '$PRESENT_VARIABLE =~ /my var/ || $EMPTY_VARIABLE =~ /nope/' | true
      '$EMPTY_VARIABLE == "" || $PRESENT_VARIABLE'                 | true
      '$PRESENT_VARIABLE != "nope" || $EMPTY_VARIABLE == ""'       | true

      '$PRESENT_VARIABLE && null || $EMPTY_VARIABLE == ""'         | true
      '$PRESENT_VARIABLE || $UNDEFINED_VARIABLE'                   | 'my variable'
      '$UNDEFINED_VARIABLE || $PRESENT_VARIABLE'                   | 'my variable'
      '$UNDEFINED_VARIABLE == null || $PRESENT_VARIABLE'           | true
      '$PRESENT_VARIABLE || $UNDEFINED_VARIABLE == null'           | 'my variable'

      '($PRESENT_VARIABLE)'                                        | 'my variable'
      '(($PRESENT_VARIABLE))'                                      | 'my variable'
      '(($PRESENT_VARIABLE && null) || $EMPTY_VARIABLE == "")'     | true
      '($PRESENT_VARIABLE) && (null || $EMPTY_VARIABLE == "")'     | true
      '("string" || "test") == "string"'                           | true
      '(null || ("test" == "string"))'                             | false
      '("string" == ("test" && "string"))'                         | true
      '("string" == ("test" || "string"))'                         | false
      '("string" == "test" || "string")'                           | "string"
      '("string" == ("string" || (("1" == "1") && ("2" == "3"))))' | true
    end

    with_them do
      let(:text) { expression }

      it "evaluates to `#{params[:value].inspect}`" do
        expect(subject.evaluate).to eq(value)
      end
    end
  end

  describe '#truthful?' do
    using RSpec::Parameterized::TableSyntax

    where(:expression, :value) do
      '$PRESENT_VARIABLE == "my variable"' | true
      "$PRESENT_VARIABLE == 'no match'"    | false
      '$UNDEFINED_VARIABLE == null'        | true
      '$PRESENT_VARIABLE'                  | true
      '$UNDEFINED_VARIABLE'                | false
      '$EMPTY_VARIABLE'                    | false
      '$INVALID = 1'                       | false
      "$PRESENT_VARIABLE =~ /var.*/"       | true
      "$UNDEFINED_VARIABLE =~ /var.*/"     | false
      "$PRESENT_VARIABLE !~ /var.*/"       | false
      "$UNDEFINED_VARIABLE !~ /var.*/"     | true
    end

    with_them do
      let(:text) { expression }

      it "returns `#{params[:value].inspect}`" do
        expect(subject.truthful?).to eq value
      end
    end

    context 'when evaluating expression raises an error' do
      let(:text) { '$PRESENT_VARIABLE' }

      it 'returns false' do
        allow(subject).to receive(:evaluate)
          .and_raise(described_class::StatementError)

        expect(subject.truthful?).to be_falsey
      end
    end
  end
end
