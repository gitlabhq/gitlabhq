require 'spec_helper'

describe KeyObserver do
  before do
    @key = double('Key',
      identifier: 'admin_654654',
      key: '== a vaild ssh key',
      projects: [],
      is_deploy_key: false
    )

    @gitolite = double('Gitlab::Gitolite',
      set_key: true,
      remove_key: true
    )

    @observer = KeyObserver.instance
    @observer.stub(gitolite: @gitolite)
  end

  context :after_save do
    it do
      @gitolite.should_receive(:set_key).with(@key.identifier, @key.key, @key.projects)
      @observer.after_save(@key)
    end
  end

  context :after_destroy do
    it do
      @gitolite.should_receive(:remove_key).with(@key.identifier, @key.projects)
      @observer.after_destroy(@key)
    end
  end
end
