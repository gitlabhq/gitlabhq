# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PathTraversal, feature_category: :shared do
  using RSpec::Parameterized::TableSyntax

  delegate :check_path_traversal!, :check_allowed_absolute_path!,
    :check_allowed_absolute_path_and_path_traversal!, to: :described_class

  describe '.check_path_traversal!' do
    it 'detects path traversal in string without any separators' do
      expect { check_path_traversal!('.') }.to raise_error(/Invalid path/)
      expect { check_path_traversal!('..') }.to raise_error(/Invalid path/)
    end

    it 'detects path traversal at the start of the string' do
      expect { check_path_traversal!('../foo') }.to raise_error(/Invalid path/)
      expect { check_path_traversal!('..\\foo') }.to raise_error(/Invalid path/)
    end

    it 'detects path traversal at the start of the string, even to just the subdirectory' do
      expect { check_path_traversal!('../') }.to raise_error(/Invalid path/)
      expect { check_path_traversal!('..\\') }.to raise_error(/Invalid path/)
      expect { check_path_traversal!('/../') }.to raise_error(/Invalid path/)
      expect { check_path_traversal!('\\..\\') }.to raise_error(/Invalid path/)
    end

    it 'detects path traversal in the middle of the string' do
      expect { check_path_traversal!('foo/../../bar') }.to raise_error(/Invalid path/)
      expect { check_path_traversal!('foo\\..\\..\\bar') }.to raise_error(/Invalid path/)
      expect { check_path_traversal!('foo/..\\bar') }.to raise_error(/Invalid path/)
      expect { check_path_traversal!('foo\\../bar') }.to raise_error(/Invalid path/)
      expect { check_path_traversal!('foo/..\\..\\..\\..\\../bar') }.to raise_error(/Invalid path/)
    end

    it 'detects path traversal at the end of the string when slash-terminates' do
      expect { check_path_traversal!('foo/../') }.to raise_error(/Invalid path/)
      expect { check_path_traversal!('foo\\..\\') }.to raise_error(/Invalid path/)
    end

    it 'detects path traversal at the end of the string' do
      expect { check_path_traversal!('foo/..') }.to raise_error(/Invalid path/)
      expect { check_path_traversal!('foo\\..') }.to raise_error(/Invalid path/)
    end

    it 'detects path traversal in string with encoded chars' do
      expect { check_path_traversal!('foo%2F..%2Fbar') }.to raise_error(/Invalid path/)
      expect { check_path_traversal!('foo%2F%2E%2E%2Fbar') }.to raise_error(/Invalid path/)
    end

    it 'detects double encoded chars' do
      expect { check_path_traversal!('foo%252F..%2Fbar') }
        .to raise_error(Gitlab::Utils::DoubleEncodingError, /is not allowed/)
      expect { check_path_traversal!('foo%252F%2E%2E%2Fbar') }
        .to raise_error(Gitlab::Utils::DoubleEncodingError, /is not allowed/)
    end

    it 'does nothing for a safe string' do
      expect(check_path_traversal!('./foo')).to eq('./foo')
      expect(check_path_traversal!('.test/foo')).to eq('.test/foo')
      expect(check_path_traversal!('..test/foo')).to eq('..test/foo')
      expect(check_path_traversal!('dir/..foo.rb')).to eq('dir/..foo.rb')
      expect(check_path_traversal!('dir/.foo.rb')).to eq('dir/.foo.rb')
    end

    it 'logs potential path traversal attempts' do
      expect(Gitlab::AppLogger).to receive(:warn)
        .with(message: "Potential path traversal attempt detected", path: "..")
      expect { check_path_traversal!('..') }.to raise_error(/Invalid path/)
    end

    it 'logs does nothing for a safe string' do
      expect(Gitlab::AppLogger).not_to receive(:warn)
        .with(message: "Potential path traversal attempt detected", path: "dir/.foo.rb")
      expect(check_path_traversal!('dir/.foo.rb')).to eq('dir/.foo.rb')
    end

    it 'does nothing for nil' do
      expect(check_path_traversal!(nil)).to be_nil
    end

    it 'does nothing for safe HashedPath' do
      expect(check_path_traversal!(Gitlab::HashedPath.new('tmp', root_hash: 1)))
        .to eq '6b/86/6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b/tmp'
    end

    it 'raises for unsafe HashedPath' do
      expect { check_path_traversal!(Gitlab::HashedPath.new('tmp', '..', 'etc', 'passwd', root_hash: 1)) }
        .to raise_error(/Invalid path/)
    end

    it 'raises for other non-strings' do
      expect { check_path_traversal!(%w[/tmp /tmp/../etc/passwd]) }.to raise_error(/Invalid path/)
    end
  end

  describe '.path_traversal?' do
    subject { described_class.path_traversal?(decoded_path, match_new_line: match_new_line) }

    where(:decoded_path, :match_new_line, :result) do
      nil                          | true  | false
      '.'                          | true  | true
      '..'                         | true  | true
      '../foo'                     | true  | true
      '..\\foo'                    | true  | true
      '../'                        | true  | true
      '..\\'                       | true  | true
      '/../'                       | true  | true
      '\\..\\'                     | true  | true
      'foo/../../bar'              | true  | true
      'foo\\..\\..\\bar'           | true  | true
      'foo/..\\bar'                | true  | true
      'foo\\../bar'                | true  | true
      'foo/..\\..\\..\\..\\../bar' | true  | true
      'foo/../'                    | true  | true
      'foo\\..\\'                  | true  | true
      'foo/..'                     | true  | true
      'foo\\..'                    | true  | true
      './foo'                      | true  | false
      '.test/foo'                  | true  | false
      '..test/foo'                 | true  | false
      'dir/..foo.rb'               | true  | false
      'dir/.foo.rb'                | true  | false

      # single quotes will escape \n ('\\n') and will not get matched.
      # we must use double quotes strings
      "./foo\n"                    | true  | true
      "..test/foo\n"               | true  | true
      "./foo\n"                    | false | false
      "..test/foo\n"               | false | false
    end

    with_them do
      it { is_expected.to eq(result) }
    end
  end

  describe '.check_allowed_absolute_path!' do
    let(:allowed_paths) { ['/home/foo'] }

    it 'raises an exception if an absolute path is not allowed' do
      expect { check_allowed_absolute_path!('/etc/passwd', allowed_paths) }.to raise_error(StandardError)
    end

    it 'does nothing for an allowed absolute path' do
      expect(check_allowed_absolute_path!('/home/foo', allowed_paths)).to be_nil
    end
  end

  describe '.check_allowed_absolute_path_and_path_traversal!' do
    let(:allowed_paths) { %w[/home/foo ./foo .test/foo ..test/foo dir/..foo.rb dir/.foo.rb] }

    it 'detects path traversal in string without any separators' do
      expect { check_allowed_absolute_path_and_path_traversal!('.', allowed_paths) }
        .to raise_error(/Invalid path/)
      expect { check_allowed_absolute_path_and_path_traversal!('..', allowed_paths) }
        .to raise_error(/Invalid path/)
    end

    it 'detects path traversal at the start of the string' do
      expect { check_allowed_absolute_path_and_path_traversal!('../foo', allowed_paths) }
        .to raise_error(/Invalid path/)
      expect { check_allowed_absolute_path_and_path_traversal!('..\\foo', allowed_paths) }
        .to raise_error(/Invalid path/)
    end

    it 'detects path traversal at the start of the string, even to just the subdirectory' do
      expect { check_allowed_absolute_path_and_path_traversal!('../', allowed_paths) }
        .to raise_error(/Invalid path/)
      expect { check_allowed_absolute_path_and_path_traversal!('..\\', allowed_paths) }
        .to raise_error(/Invalid path/)
      expect { check_allowed_absolute_path_and_path_traversal!('/../', allowed_paths) }
        .to raise_error(/Invalid path/)
      expect { check_allowed_absolute_path_and_path_traversal!('\\..\\', allowed_paths) }
        .to raise_error(/Invalid path/)
    end

    it 'detects path traversal in the middle of the string' do
      expect { check_allowed_absolute_path_and_path_traversal!('foo/../../bar', allowed_paths) }
        .to raise_error(/Invalid path/)
      expect { check_allowed_absolute_path_and_path_traversal!('foo\\..\\..\\bar', allowed_paths) }
        .to raise_error(/Invalid path/)
      expect { check_allowed_absolute_path_and_path_traversal!('foo/..\\bar', allowed_paths) }
        .to raise_error(/Invalid path/)
      expect { check_allowed_absolute_path_and_path_traversal!('foo\\../bar', allowed_paths) }
        .to raise_error(/Invalid path/)
      expect { check_allowed_absolute_path_and_path_traversal!('foo/..\\..\\..\\..\\../bar', allowed_paths) }
        .to raise_error(/Invalid path/)
    end

    it 'detects path traversal at the end of the string when slash-terminates' do
      expect { check_allowed_absolute_path_and_path_traversal!('foo/../', allowed_paths) }
        .to raise_error(/Invalid path/)
      expect { check_allowed_absolute_path_and_path_traversal!('foo\\..\\', allowed_paths) }
        .to raise_error(/Invalid path/)
    end

    it 'detects path traversal at the end of the string' do
      expect { check_allowed_absolute_path_and_path_traversal!('foo/..', allowed_paths) }
        .to raise_error(/Invalid path/)
      expect { check_allowed_absolute_path_and_path_traversal!('foo\\..', allowed_paths) }
        .to raise_error(/Invalid path/)
    end

    it 'does not return errors for a safe string' do
      expect(check_allowed_absolute_path_and_path_traversal!('./foo', allowed_paths)).to be_nil
      expect(check_allowed_absolute_path_and_path_traversal!('.test/foo', allowed_paths)).to be_nil
      expect(check_allowed_absolute_path_and_path_traversal!('..test/foo', allowed_paths)).to be_nil
      expect(check_allowed_absolute_path_and_path_traversal!('dir/..foo.rb', allowed_paths)).to be_nil
      expect(check_allowed_absolute_path_and_path_traversal!('dir/.foo.rb', allowed_paths)).to be_nil
    end

    it 'raises error for a non-string' do
      expect { check_allowed_absolute_path_and_path_traversal!(nil, allowed_paths) }.to raise_error(StandardError)
    end

    it 'raises an exception if an absolute path is not allowed' do
      expect { check_allowed_absolute_path!('/etc/passwd', allowed_paths) }.to raise_error(StandardError)
    end

    it 'does nothing for an allowed absolute path' do
      expect(check_allowed_absolute_path!('/home/foo', allowed_paths)).to be_nil
    end
  end
end
