# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UrlSanitizer do
  using RSpec::Parameterized::TableSyntax

  describe '.sanitize' do
    def sanitize_url(url)
      # We want to try with multi-line content because is how error messages are formatted
      described_class.sanitize(%(
         remote: Not Found
         fatal: repository `#{url}` not found
      ))
    end

    where(:input, :output) do
      # http(s), ssh, git, relative, and schemeless URLs should all be masked correctly
      urls = ['http://', 'https://', 'ssh://', 'git://', '//', ''].flat_map do |protocol|
        [
          ["#{protocol}test.com", "#{protocol}test.com"],
          ["#{protocol}test.com/", "#{protocol}test.com/"],
          ["#{protocol}test.com/path/to/repo.git", "#{protocol}test.com/path/to/repo.git"],
          ["#{protocol}user@test.com", "#{protocol}*****@test.com"],
          ["#{protocol}user:pass@test.com", "#{protocol}*****:*****@test.com"],
          ["#{protocol}user:@test.com", "#{protocol}*****@test.com"],
          ["#{protocol}:pass@test.com", "#{protocol}:*****@test.com"]
        ]
      end

      # SCP-style URLs are left unmodified
      urls << ['user@server:project.git', 'user@server:project.git']
      urls << ['user:@server:project.git', 'user:@server:project.git']
      urls << [':pass@server:project.git', ':pass@server:project.git']
      urls << ['user:pass@server:project.git', 'user:pass@server:project.git']
      urls << ['user:pass@server:123project.git', 'user:pass@server:123project.git']
      urls << ['user:pass@server:1project3.git', 'user:pass@server:1project3.git']
      urls << ['user:pass@server:project123.git', 'user:pass@server:project123.git']
      urls << ['root@host:/root/ids/rules.tar.gz', 'root@host:/root/ids/rules.tar.gz']

      # actual URLs that look like SCP-styled URLS
      urls << ['username:password@test.com', '*****:*****@test.com']
      urls << ['username:password@test.com:1234', '*****:*****@test.com:1234']
      urls << ['username:password@test.com:1234/org/project', '*****:*****@test.com:1234/org/project']
      urls << ['username:password@test.com:1234/org/project.git', '*****:*****@test.com:1234/org/project.git']

      # return an empty string for invalid URLs
      urls << ['ssh://', '']
    end

    with_them do
      it { expect(sanitize_url(input)).to include("repository `#{output}` not found") }
    end
  end

  describe '.valid?' do
    where(:value, :url) do
      false | nil
      false | ''
      false | '123://invalid:url'
      false | 'valid@project:url.git'
      false | 'valid:pass@project:url.git'
      false | %w[test array]
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

  describe '.valid_web?' do
    where(:value, :url) do
      false | nil
      false | ''
      false | '123://invalid:url'
      false | 'valid@project:url.git'
      false | 'valid:pass@project:url.git'
      false | %w[test array]
      false | 'ssh://example.com'
      false | 'ssh://:@example.com'
      false | 'ssh://foo@example.com'
      false | 'ssh://foo:bar@example.com'
      false | 'ssh://foo:bar@example.com/group/group/project.git'
      false | 'git://example.com/group/group/project.git'
      false | 'git://foo:bar@example.com/group/group/project.git'
      true  | 'http://foo:bar@example.com/group/group/project.git'
      true  | 'https://foo:bar@example.com/group/group/project.git'
    end

    with_them do
      it { expect(described_class.valid_web?(url)).to eq(value) }
    end
  end

  describe '.sanitize_masked_url' do
    where(:original_url, :masked_url) do
      'http://{domain}.com'     | 'http://{domain}.com'
      'http://{domain}/{hook}'  | 'http://{domain}/{hook}'
      'http://user:pass@{domain}/hook' | 'http://*****:*****@{domain}/hook'
      'http://user:pass@{domain}:{port}/hook' | 'http://*****:*****@{domain}:{port}/hook'
      'http://user:@{domain}:{port}/hook' | 'http://*****:*****@{domain}:{port}/hook'
      'http://:pass@{domain}:{port}/hook' | 'http://*****:*****@{domain}:{port}/hook'
      'http://user@{domain}:{port}/hook' | 'http://*****:*****@{domain}:{port}/hook'
      'http://u:p@{domain}/hook?email=james@example.com' | 'http://*****:*****@{domain}/hook?email=james@example.com'
      'http://{domain}/hook?email=james@example.com' | 'http://{domain}/hook?email=james@example.com'
      'http://user:{pass}@example.com' | 'http://*****:*****@example.com'
    end

    with_them do
      it { expect(described_class.sanitize_masked_url(original_url)).to eq(masked_url) }
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
        'http://foo:bar:baz@example.com' | { user: 'foo', password: 'bar:baz' }
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

    context 'with mixed credentials' do
      where(:url, :credentials, :result) do
        'http://a@example.com'   | { password: 'd' } | { user: 'a', password: 'd' }
        'http://a:b@example.com' | { password: 'd' } | { user: 'a', password: 'd' }
        'http://:b@example.com'  | { password: 'd' } | { user: nil, password: 'd' }
        'http://a@example.com'   | { user: 'c' }     | { user: 'c', password: nil }
        'http://a:b@example.com' | { user: 'c' }     | { user: 'c', password: 'b' }
        'http://a:b@example.com' | { user: '' }      | { user: 'a', password: 'b' }
      end

      with_them do
        subject { described_class.new(url, credentials: credentials).credentials }

        it { is_expected.to eq(result) }
      end
    end
  end

  describe '#user' do
    context 'credentials in hash' do
      it 'overrides URL-provided user' do
        sanitizer = described_class.new('http://a:b@example.com', credentials: { user: 'c', password: 'd' })

        expect(sanitizer.user).to eq('c')
      end
    end

    context 'credentials in URL' do
      where(:url, :user) do
        'http://foo:bar@example.com' | 'foo'
        'http://foo:bar:baz@example.com' | 'foo'
        'http://:bar@example.com'    | nil
        'http://foo:@example.com'    | 'foo'
        'http://foo@example.com'     | 'foo'
        'http://:@example.com'       | nil
        'http://@example.com'        | nil
        'http://example.com'         | nil

        # Other invalid URLs
        nil  | nil
        ''   | nil
        'no' | nil
      end

      with_them do
        subject { described_class.new(url).user }

        it { is_expected.to eq(user) }
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
        'http://foo:g p@example.com' | 'http://foo:g%20p@example.com'
        'http://foo:s/h@example.com' | 'http://foo:s%2Fh@example.com'
        'http://t u:a#b@example.com' | 'http://t%20u:a%23b@example.com'
        'http://t+u:a#b@example.com' | 'http://t%2Bu:a%23b@example.com'
      end

      with_them do
        let(:expected) { output == :same ? input : output }

        it { expect(described_class.new(input).full_url).to eq(expected) }
      end
    end
  end

  context 'when credentials contains special chars' do
    it 'parses the URL without errors' do
      url_sanitizer = described_class.new("https://foo:b?r@github.com/me/project.git")

      expect(url_sanitizer.sanitized_url).to eq("https://github.com/me/project.git")
      expect(url_sanitizer.full_url).to eq("https://foo:b%3Fr@github.com/me/project.git")
    end
  end
end
