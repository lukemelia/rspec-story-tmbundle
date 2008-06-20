require File.dirname(__FILE__) + '/../../../../spec_helper'
require File.dirname(__FILE__) + '/../../../../../lib/spec/mate/story/files'

module Spec
  module Mate
    module Story
      module Files
      
        describe StepsFile do
          before(:each) do
            @fixtures_path = File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. .. .. .. fixtures]))
            @steps_file = StepsFile.new(File.expand_path(File.join(@fixtures_path, %w[stories steps basic.rb])))
          end
          
          describe "#name" do
            it "should return the simple name (based off the file name)" do
              @steps_file.name.should == 'basic'
            end
          end
          
          describe "#story_files_and_names" do
            before(:each) do
              @basic_story_file = mock('basic story file', :name => 'basic', :file_path => "#{@fixtures_path}/stories/basic/one_basic.story", :includes_step_file? => true)
            end
            
            it "should create StoryFile objects for each story file found in the filesystem" do
              StoryFile.stub!(:new).and_return(@basic_story_file)

              # expect
              StoryFile.should_receive(:new).at_least(:once).with(/\/stories\/basic\/one_basic.story$/).and_return(@basic_story_file)
              
              # when
              @steps_file.story_files_and_names
            end
            
            it "should generate a list of story files (and names) which use this steps file" do
              @steps_file.story_files_and_names.should ==
                [
                  {:name=>"additional basic story", :file_path=>"#{@fixtures_path}/stories/basic/additional_basic.story"},
                  {:name=>"one basic story", :file_path=>"#{@fixtures_path}/stories/basic/one_basic.story"}
                ]
            end
          end
          
          describe "#referenced_steps_files" do
            describe "when the file path initially passed to initialize is not a steps file" do
              before(:each) do
                @steps_file = StepsFile.new(File.expand_path(File.join(@fixtures_path, %w[stories helper.rb])))
              end
        
              it "should return a blank array of step files" do
                @steps_file.referenced_steps_files.should == []
              end                  
            end
            
            describe "when this step file doesn't exist" do
              before(:each) do
                File.stub!(:file?).and_return(false)
              end
        
              it "should return a blank array of step files" do
                @steps_file.referenced_steps_files.should == []
              end
            end

            it "should generate a list of StepFiles representing steps included in this one using include_steps_for" do
              @steps_file.referenced_steps_files.should ==
                [
                  StepsFile.new("#{@fixtures_path}/stories/steps/global.rb")
                ]
            end
          end
          
          describe "#referenced_step_files_and_names" do
            it "should generate a list of hashes representing steps included in this one using include_steps_for" do
              @steps_file.referenced_step_files_and_names.should ==
                [
                  { :name => 'global steps', :file_path => "#{@fixtures_path}/stories/steps/global.rb" }
                ]
            end
          end
          describe "#step_definitions" do
            before(:each) do
              Spec::Story::Step.stub!(:new).and_return(@step = mock('step'))
            end
            
            it "should return a list of step definitions included in this file" do
              @steps_file.step_definitions.should ==
                [
                  {:step => @step, :type => 'Given', :pattern => "Basic step (given)", :line => 7, :column => 5, :file_path => @steps_file.full_file_path, :group_tag => 'basic'},
                  {:step => @step, :type => 'Given', :pattern => "another basic step", :line => 11, :column => 5, :file_path => @steps_file.full_file_path, :group_tag => 'basic'},
                  {:step => @step, :type => 'Given', :pattern => %r{Basic regexp \(given\)}, :line => 15, :column => 5, :file_path => @steps_file.full_file_path, :group_tag => 'basic'},
                  {:step => @step, :type => 'When', :pattern => "Basic when", :line => 19, :column => 5, :file_path => @steps_file.full_file_path, :group_tag => 'basic'},
                  {:step => @step, :type => 'Then', :pattern => "Basic then", :line => 23, :column => 5, :file_path => @steps_file.full_file_path, :group_tag => 'basic'},
                ]
            end
          end
        end
        
      end
    end
  end
end