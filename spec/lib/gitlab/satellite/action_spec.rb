require 'spec_helper'

describe 'Gitlab::Satellite::Action' do


  let(:project) { create(:project_with_code) }
  let(:user) { create(:user) }


  describe '#prepare_satellite!' do

    it 'create a repository with a parking branch and one remote: origin' do
      repo = project.satellite.repo

      #now lets dirty it up

      starting_remote_count = repo.git.list_remotes.size
      starting_remote_count.should >= 1
      #kind of hookey way to add a second remote
      origin_uri = repo.git.remote({v: true}).split(" ")[1]
    begin
      repo.git.remote({raise: true}, 'add', 'another-remote', origin_uri)
      repo.git.branch({raise: true}, 'a-new-branch')

      repo.heads.size.should > (starting_remote_count)
      repo.git.remote().split(" ").size.should > (starting_remote_count)
    rescue
    end

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


  describe '#in_locked_and_timed_satellite' do

    it 'should make use of a lockfile' do
      repo = project.satellite.repo
      called = false

      #set assumptions
      File.rm(project.satellite.lock_file) unless !File.exists? project.satellite.lock_file

      File.exists?(project.satellite.lock_file).should be_false

      satellite_action = Gitlab::Satellite::Action.new(user, project)
      satellite_action.send(:in_locked_and_timed_satellite) do |sat_repo|
        repo.should == sat_repo
        (File.exists? project.satellite.lock_file).should be_true
        called = true
      end

      called.should be_true

    end

    it 'should be able to use the satellite after locking' do
      pending "can't test this, doesn't seem to be a way to the the flock status on a file, throwing piles of processes at it seems lousy too"
      repo = project.satellite.repo
      first_call = false

      (File.exists? project.satellite.lock_file).should be_false

      test_file = ->(called) {
        File.exists?(project.satellite.lock_file).should be_true
        called.should be_true
        File.readlines.should == "some test code"
        File.truncate(project.satellite.lock, 0)
        File.readlines.should == ""
      }

      write_file = ->(called, checker) {
        if (File.exists?(project.satellite.lock_file))
          file = File.open(project.satellite.lock, '+w')
          file.write("some test code")
          file.close
          checker.call(called)
        end
      }


      satellite_action = Gitlab::Satellite::Action.new(user, project)
      satellite_action.send(:in_locked_and_timed_satellite) do |sat_repo|
        write_file.call(first_call, test_file)
        first_call = true
        repo.should == sat_repo
        (File.exists? project.satellite.lock_file).should be_true

      end

      first_call.should be_true
      puts File.stat(project.satellite.lock_file).inspect

      second_call = false
      satellite_action.send(:in_locked_and_timed_satellite) do |sat_repo|
        write_file.call(second_call, test_file)
        second_call = true
        repo.should == sat_repo
        (File.exists? project.satellite.lock_file).should be_true
      end

      second_call.should be_true
      (File.exists? project.satellite.lock_file).should be_true
    end

  end
end

