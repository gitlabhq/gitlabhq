require 'rails_helper'

describe RemoteMirror, focus: true do
  describe 'encrypting credentials' do
    context 'when setting URL for a first time' do
      it 'should store the URL without credentials' do
        mirror = create_mirror_with_url('http://foo:bar@test.com')

        expect(mirror.read_attribute(:url)).to eq('http://test.com')
      end

      it 'should store the credentials on a separate field' do
        mirror = create_mirror_with_url('http://foo:bar@test.com')

        expect(mirror.credentials).to eq({ user: 'foo', password: 'bar' })
      end
    end

    context 'when updating the URL' do
      it 'should allow a new URL without credentials' do
        mirror = create_mirror_with_url('http://foo:bar@test.com')

        mirror.update_attribute(:url, 'http://test.com')

        expect(mirror.url).to eq('http://test.com')
        expect(mirror.credentials).to eq({ user: nil, password: nil })
      end

      it 'should allow a new URL with credentials' do
        mirror = create_mirror_with_url('http://test.com')

        mirror.update_attribute(:url, 'http://foo:bar@test.com')

        expect(mirror.url).to eq('http://foo:bar@test.com')
        expect(mirror.credentials).to eq({ user: 'foo', password: 'bar' })
      end
    end
  end

  describe '#safe_url' do
    context 'when URL contains credentials' do
      it 'should mask the credentials' do
        mirror = create_mirror_with_url('http://foo:bar@test.com')

        expect(mirror.safe_url).to eq('http://*****:*****@test.com')
      end
    end

    context 'when URL does not contain credentials' do
      it 'should show the full URL' do
        mirror = create_mirror_with_url('http://test.com')

        expect(mirror.safe_url).to eq('http://test.com')
      end
    end
  end

  def create_mirror_with_url(url)
    project = FactoryGirl.create(:project)
    project.remote_mirrors.create!(url: url)
  end
end
