require 'spec_helper'

describe UrlPlaceholderValidator do
  let(:validator) { described_class.new(attributes: [:link_url],  **options) }
  let!(:badge) { build(:badge) }
  let(:placeholder_url) { 'http://www.example.com/%{project_path}/%{project_id}/%{default_branch}/%{commit_sha}' }

  subject { validator.validate_each(badge, :link_url, badge.link_url) }

  describe '#validates_each' do
    context 'with no options' do
      let(:options) { {} }

      it 'allows http and https protocols by default' do
        expect(validator.send(:default_options)[:protocols]).to eq %w(http https)
      end

      it 'checks that the url structure is valid' do
        badge.link_url = placeholder_url

        subject

        expect(badge.errors.empty?).to be false
      end
    end

    context 'with placeholder regex' do
      let(:options) { { placeholder_regex: /(project_path|project_id|commit_sha|default_branch)/ } }

      it 'checks that the url is valid and obviate placeholders that match regex' do
        badge.link_url = placeholder_url

        subject

        expect(badge.errors.empty?).to be true
      end
    end
  end
end
