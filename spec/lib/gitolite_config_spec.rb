require 'spec_helper'

describe Gitlab::GitoliteConfig do
  let(:gitolite) { Gitlab::GitoliteConfig.new }

  it { should respond_to :write_key }
  it { should respond_to :rm_key }
  it { should respond_to :update_project }
  it { should respond_to :update_project! }
  it { should respond_to :update_projects }
  it { should respond_to :destroy_project }
  it { should respond_to :destroy_project! }
  it { should respond_to :apply }
  it { should respond_to :admin_all_repo }
  it { should respond_to :admin_all_repo! }
end
