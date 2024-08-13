# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VirtualRegistries::Packages::Maven::Upstream, type: :model, feature_category: :virtual_registry do
  using RSpec::Parameterized::TableSyntax

  subject(:upstream) { build(:virtual_registries_packages_maven_upstream) }

  describe 'associations' do
    it do
      is_expected.to have_many(:cached_responses)
        .class_name('VirtualRegistries::Packages::Maven::CachedResponse')
        .inverse_of(:upstream)
    end

    it do
      is_expected.to have_one(:registry_upstream)
        .class_name('VirtualRegistries::Packages::Maven::RegistryUpstream')
        .inverse_of(:upstream)
    end

    it do
      is_expected.to have_one(:registry)
        .through(:registry_upstream)
        .class_name('VirtualRegistries::Packages::Maven::Registry')
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_presence_of(:password) }
    it { is_expected.to validate_length_of(:url).is_at_most(255) }
    it { is_expected.to validate_length_of(:username).is_at_most(255) }
    it { is_expected.to validate_length_of(:password).is_at_most(255) }

    context 'for url' do
      where(:url, :valid, :error_messages) do
        'http://test.maven'   | true  | nil
        'https://test.maven'  | true  | nil
        'git://test.maven'    | false | ['Url is blocked: Only allowed schemes are http, https']
        nil                   | false | ["Url can't be blank", 'Url must be a valid URL']
        ''                    | false | ["Url can't be blank", 'Url must be a valid URL']
        "http://#{'a' * 255}" | false | 'Url is too long (maximum is 255 characters)'
        'http://127.0.0.1'    | false | 'Url is blocked: Requests to localhost are not allowed'
        'maven.local'         | false | 'Url is blocked: Only allowed schemes are http, https'
        'http://192.168.1.2'  | false | 'Url is blocked: Requests to the local network are not allowed'
      end

      with_them do
        before do
          upstream.url = url
        end

        if params[:valid]
          it { expect(upstream).to be_valid }
        else
          it do
            expect(upstream).not_to be_valid
            expect(upstream.errors).to contain_exactly(*error_messages)
          end
        end
      end
    end

    context 'for credentials' do
      where(:username, :password, :valid, :error_message) do
        'user'      | 'password'   | true  | nil
        ''          | ''           | true  | nil
        ''          | nil          | true  | nil
        nil         | ''           | true  | nil
        nil         | 'password'   | false | "Username can't be blank"
        'user'      | nil          | false | "Password can't be blank"
        ''          | 'password'   | false | "Username can't be blank"
        'user'      | ''           | false | "Password can't be blank"
        ('a' * 256) | 'password'   | false | 'Username is too long (maximum is 255 characters)'
        'user'      | ('a' * 256)  | false | 'Password is too long (maximum is 255 characters)'
      end

      with_them do
        before do
          upstream.username = username
          upstream.password = password
        end

        if params[:valid]
          it { expect(upstream).to be_valid }
        else
          it do
            expect(upstream).not_to be_valid
            expect(upstream.errors).to contain_exactly(error_message)
          end
        end
      end

      context 'when url is updated' do
        where(:new_url, :new_user, :new_pwd, :expected_user, :expected_pwd, :expected_credentials) do
          'http://original_url.test' | 'test' | 'test' | 'test' | 'test' | { 'username' => 'test', 'password' => 'test' }
          'http://update_url.test'   | 'test' | 'test' | 'test' | 'test' | { 'username' => 'test', 'password' => 'test' }
          'http://update_url.test'   | :none  | :none  | nil    | nil    | { 'username' => nil, 'password' => nil }
          'http://update_url.test'   | 'test' | :none  | nil    | nil    | { 'username' => nil, 'password' => nil }
          'http://update_url.test'   | :none  | 'test' | nil    | nil    | { 'username' => nil, 'password' => nil }
        end

        with_them do
          before do
            upstream.update!(url: 'http://original_url.test', username: 'original_user', password: 'original_pwd')
          end

          it 'resets the username and the password when necessary' do
            new_attributes = { url: new_url, username: new_user, password: new_pwd }.select { |_, v| v != :none }
            upstream.update!(new_attributes)

            expect(upstream.reload.url).to eq(new_url)
            expect(upstream.username).to eq(expected_user)
            expect(upstream.password).to eq(expected_pwd)
            expect(upstream.credentials).to eq(expected_credentials)
          end
        end
      end
    end
  end

  context 'for credentials persistance' do
    it 'persists and reads back credentials properly' do
      upstream.username = 'test'
      upstream.password = 'test'

      upstream.save!

      upstream_read = upstream.reload
      expect(upstream_read.username).to eq('test')
      expect(upstream_read.password).to eq('test')
    end
  end

  describe '#url_for' do
    subject { upstream.url_for(path) }

    where(:path, :expected_url) do
      'path'      | 'http://test.maven/path'
      ''          | 'http://test.maven/'
      '/path'     | 'http://test.maven/path'
      '/sub/path' | 'http://test.maven/sub/path'
    end

    with_them do
      before do
        upstream.url = 'http://test.maven/'
      end

      it { is_expected.to eq(expected_url) }
    end
  end

  describe '#headers' do
    subject { upstream.headers }

    where(:username, :password, :expected_headers) do
      'user' | 'pass' | { Authorization: 'Basic dXNlcjpwYXNz' }
      'user' | ''     | {}
      ''     | 'pass' | {}
      ''     | ''     | {}
    end

    with_them do
      before do
        upstream.username = username
        upstream.password = password
      end

      it { is_expected.to eq(expected_headers) }
    end
  end

  describe '#as_json' do
    subject { upstream.as_json }

    it { is_expected.not_to include('username', 'password') }
  end
end
