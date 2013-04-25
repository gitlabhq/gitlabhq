require 'spec_helper'

describe 'Gitlab::Satellite::Action' do


  let(:project) { create(:project_with_code) }
  let(:user) { create(:user) }


  describe '#prepare_satellite!' do


    it 'create a repository with a parking branch and one remote; origin' do
      repo = project.satellite.repo

      #now lets dirty it up
      repo.git.list_remotes.size.should == 1
      #kind of hookey way to add a second remote
      origin_uri = repo.git.remote({v:true}).split(" ")[1]
      repo.git.remote({raise:true},'add','another-remote',origin_uri )
      repo.git.branch({raise:true}, 'a-new-branch')
      repo.heads.size.should == 2
      repo.git.remote().split(" ").size.should == 2
      repo.git.config({}, "user.name", "#{user.name} -- foo")
      repo.git.config({}, "user.email", "#{user.email} -- foo")
      repo.config['user.name'].should =="#{user.name} -- foo"
      repo.config['user.email'].should =="#{user.email} -- foo"


      #These must happen in the context of the satellite directory...
      satellite_action = Gitlab::Satellite::Action.new(user, project)
      project.satellite.lock {
        #Now clean it up, use send to get around prepare_satellite! being protected
        satellite_action.send(:prepare_satellite!, repo)
      }

      #verify it's clean
      heads = repo.heads.map(&:name)
      heads.size.should == 1
      heads.include?(Gitlab::Satellite::Satellite::PARKING_BRANCH).should == true
      remotes = repo.git.remote().split(' ')
      remotes.size.should == 1
      remotes.include?('origin').should == true
      repo.config['user.name'].should ==user.name
      repo.config['user.email'].should ==user.email
    end


  end
end

