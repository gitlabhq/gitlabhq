require 'rails_helper'

describe Gitlab::DependencyLinker::PodspecLinker do
  describe '.support?' do
    it 'supports *.podspec' do
      expect(described_class.support?('Reachability.podspec')).to be_truthy
    end

    it 'does not support other files' do
      expect(described_class.support?('.podspec.example')).to be_falsey
    end
  end

  describe '#link' do
    let(:file_name) { "Reachability.podspec" }

    let(:file_content) do
      <<-CONTENT.strip_heredoc
        Pod::Spec.new do |spec|
          spec.name         = 'Reachability'
          spec.version      = '3.1.0'
          spec.license      = { :type => 'GPL-3.0' }
          spec.license      = "MIT"
          spec.license      = { type: 'Apache-2.0' }
          spec.homepage     = 'https://github.com/tonymillion/Reachability'
          spec.authors      = { 'Tony Million' => 'tonymillion@gmail.com' }
          spec.summary      = 'ARC and GCD Compatible Reachability Class for iOS and OS X.'
          spec.source       = { :git => 'https://github.com/tonymillion/Reachability.git', :tag => 'v3.1.0' }
          spec.source_files = 'Reachability.{h,m}'
          spec.framework    = 'SystemConfiguration'

          spec.dependency 'AFNetworking', '~> 1.0'
          spec.dependency 'RestKit/CoreData', '~> 0.20.0'
          spec.ios.dependency 'MBProgressHUD', '~> 0.5'
        end
      CONTENT
    end

    subject { Gitlab::Highlight.highlight(file_name, file_content) }

    def link(name, url)
      %{<a href="#{url}" rel="nofollow noreferrer noopener" target="_blank">#{name}</a>}
    end

    it 'links the gem name' do
      expect(subject).to include(link('Reachability', 'https://cocoapods.org/pods/Reachability'))
    end

    it 'links the license' do
      expect(subject).to include(link('GPL-3.0', 'http://choosealicense.com/licenses/gpl-3.0/'))
      expect(subject).to include(link('MIT', 'http://choosealicense.com/licenses/mit/'))
      expect(subject).to include(link('Apache-2.0', 'http://choosealicense.com/licenses/apache-2.0/'))
    end

    it 'links the homepage' do
      expect(subject).to include(link('https://github.com/tonymillion/Reachability', 'https://github.com/tonymillion/Reachability'))
    end

    it 'links the source URL' do
      expect(subject).to include(link('https://github.com/tonymillion/Reachability.git', 'https://github.com/tonymillion/Reachability.git'))
    end

    it 'links dependencies' do
      expect(subject).to include(link('AFNetworking', 'https://cocoapods.org/pods/AFNetworking'))
      expect(subject).to include(link('RestKit/CoreData', 'https://cocoapods.org/pods/RestKit'))
      expect(subject).to include(link('MBProgressHUD', 'https://cocoapods.org/pods/MBProgressHUD'))
    end
  end
end
