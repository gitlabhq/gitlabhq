require 'spec_helper'

describe Gitlab::UrlSanitizer do
  using RSpec::Parameterized::TableSyntax

  describe '.sanitize' do
    def sanitize_url(url)
      # We want to try with multi-line content because is how error messages are formatted
      described_class.sanitize(%Q{
         remote: Not Found
         fatal: repository '#{url}' not found
      })
    end

    where(:input, :output) do
      'http://user:pass@test.com/root/repoC.git/'  | 'http://*****:*****@test.com/root/repoC.git/'
      'https://user:pass@test.com/root/repoA.git/' | 'https://*****:*****@test.com/root/repoA.git/'
      'ssh://user@host.test/path/to/repo.git'      | 'ssh://*****@host.test/path/to/repo.git'

      # git protocol does not support authentication but clean any details anyway
      'git://user:pass@host.test/path/to/repo.git' | 'git://*****:*****@host.test/path/to/repo.git'
      'git://host.test/path/to/repo.git'           | 'git://host.test/path/to/repo.git'

      # SCP-style URLs are left unmodified
      'user@server:project.git'      | 'user@server:project.git'
      'user:pass@server:project.git' | 'user:pass@server:project.git'

      # return an empty string for invalid URLs
      'ssh://' | ''
    end

    with_them do
      it { expect(sanitize_url(input)).to include("repository '#{output}' not found") }
    end
  end

  describe '.valid?' do
    where(:value, :url) do
      false | nil
      false | ''
      false | '123://invalid:url'
      false | 'valid@project:url.git'
      false | 'valid:pass@project:url.git'
      true  | 'ssh://example.com'
      true  | 'ssh://:@example.com'
      true  | 'ssh://foo@example.com'
      true  | 'ssh://foo:bar@example.com'
      true  | 'ssh://foo:bar@example.com/group/group/project.git'
      true  | 'git://example.com/group/group/project.git'
      true  | 'git://foo:bar@example.com/group/group/project.git'
      true  | 'http://foo:bar@example.com/group/group/project.git'
      true  | 'https://foo:bar@example.com/group/group/project.git'
    end

    with_them do
      it { expect(described_class.valid?(url)).to eq(value) }
    end
  end

  describe '#sanitized_url' do
    context 'credentials in hash' do
      where(username: ['foo', '', nil], password: ['bar', '', nil])

      with_them do
        let(:credentials) { { user: username, password: password } }
        subject { described_class.new('http://example.com', credentials: credentials).sanitized_url }

        it { is_expected.to eq('http://example.com') }
      end
    end

    context 'credentials in URL' do
      where(userinfo: %w[foo:bar@ foo@ :bar@ :@ @] + [nil])

      with_them do
        subject { described_class.new("http://#{userinfo}example.com").sanitized_url }

        it { is_expected.to eq('http://example.com') }
      end
    end
  end

  describe '#credentials' do
    context 'credentials in hash' do
      it 'overrides URL-provided credentials' do
        sanitizer = described_class.new('http://a:b@example.com', credentials: { user: 'c', password: 'd' })

        expect(sanitizer.credentials).to eq(user: 'c', password: 'd')
      end
    end

    context 'credentials in URL' do
      where(:url, :credentials) do
        'http://foo:bar@example.com' | { user: 'foo', password: 'bar' }
        'http://:bar@example.com'    | { user: nil,   password: 'bar' }
        'http://foo:@example.com'    | { user: 'foo', password: nil }
        'http://foo@example.com'     | { user: 'foo', password: nil }
        'http://:@example.com'       | { user: nil,   password: nil }
        'http://@example.com'        | { user: nil,   password: nil }
        'http://example.com'         | { user: nil,   password: nil }

        # Other invalid URLs
        nil  | { user: nil, password: nil }
        ''   | { user: nil, password: nil }
        'no' | { user: nil, password: nil }
      end

      with_them do
        subject { described_class.new(url).credentials }

        it { is_expected.to eq(credentials) }
      end
    end
  end

  describe '#full_url' do
    context 'credentials in hash' do
      where(:credentials, :userinfo) do
        { user: 'foo', password: 'bar' } | 'foo:bar@'
        { user: 'foo', password: ''    } | 'foo@'
        { user: 'foo', password: nil   } | 'foo@'
        { user: '',    password: 'bar' } | ':bar@'
        { user: '',    password: ''    } | nil
        { user: '',    password: nil   } | nil
        { user: nil,   password: 'bar' } | ':bar@'
        { user: nil,   password: ''    } | nil
        { user: nil,   password: nil   } | nil
      end

      with_them do
        subject { described_class.new('http://example.com', credentials: credentials).full_url }

        it { is_expected.to eq("http://#{userinfo}example.com") }
      end
    end

    context 'credentials in URL' do
      where(:input, :output) do
        nil                          | ''
        ''                           | :same
        'git@example.com'            | :same
        'http://example.com'         | :same
        'http://foo@example.com'     | :same
        'http://foo:@example.com'    | 'http://foo@example.com'
        'http://:bar@example.com'    | :same
        'http://foo:bar@example.com' | :same
      end

      with_them do
        let(:expected) { output == :same ? input : output }

        it { expect(described_class.new(input).full_url).to eq(expected) }
      end
    end
  end

  context 'when credentials contains special chars' do
    it 'should parse the URL without errors' do
      url_sanitizer = described_class.new("https://foo:b?r@github.com/me/project.git")

      expect(url_sanitizer.sanitized_url).to eq("https://github.com/me/project.git")
      expect(url_sanitizer.full_url).to eq("https://foo:b?r@github.com/me/project.git")
    end
  end
end
