require File.dirname(__FILE__) + '/../../../spec_helper'
require File.dirname(__FILE__) + '/../../../../lib/spec/mate/story/story_helper'

module Spec
  module Mate
    module Story
      
      describe StoryHelper do
        before(:each) do
          @fixtures_path = File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. .. .. fixtures]))
          # Default - don't let TextMateHelper actually perform any actions
          TextMateHelper.stub!(:goto_file)
          TextMateHelper.stub!(:display_select_list)
          TextMateHelper.stub!(:request_confirmation)
          TextMateHelper.stub!(:create_and_open_file)
          TextMateHelper.stub!(:insert_text)
          TextMateHelper.stub!(:create_file)
          
          File.stub!(:file?).and_return(true)
          
          @helper_file = mock('helper file',
                          :is_story_file? => false,
                          :is_step_file? => false,
                          :story_file_path => '/path/to/story/file',
                          :primary_steps_file_path => '/path/to/steps/file',
                          :alternate_files_and_names => [
                              {:name => 'one', :file_path => "/path/to/one"},
                              {:name => 'two', :file_path => "/path/to/two"}
                          ])
                          
          Files::Base.stub!(:create_from_file_path).and_return(@helper_file)
          Files::Base.stub!(:default_content_for).and_return('')
          @story_helper = StoryHelper.new("#{@fixtures_path}/stories/basic/one_basic.story")
        end
        
        describe "in a story file" do
          before(:each) do
            @helper_file.stub!(:is_story_file?).and_return(true)
            @helper_file.stub!(:alternate_file_path).and_return("/path/steps/one.rb")
          end
          describe "#go_to_alternate_file" do
            describe "when the primary step matcher file exists" do
              it "should go to primary step matcher" do
                # expects
                TextMateHelper.should_receive('goto_file').with('/path/steps/one.rb', :line => 1, :column => 1)
                # when
                @story_helper.goto_alternate_file
              end
            end
            
            describe "when the primary step matcher file does not exist" do
              before(:each) do
                File.stub!(:file?).and_return(false)
              end
              
              it "should ask if the file should be created" do
                # expects
                TextMateHelper.should_receive('request_confirmation')
                # when
                @story_helper.goto_alternate_file
              end
              
              describe "when the user chooses to create the file" do
                before(:each) do
                  TextMateHelper.stub!(:request_confirmation).and_return(true)
                end

                it "should create the file and add the default contents" do
                  # expects
                  TextMateHelper.should_receive('create_and_open_file').with('/path/steps/one.rb')
                  TextMateHelper.should_receive('insert_text')
                  # when
                  @story_helper.goto_alternate_file
                end
              end

              describe "when the user chooses NOT to create the file" do
                before(:each) do
                  TextMateHelper.stub!(:request_confirmation).and_return(false)
                end

                it "should not create the file" do
                  # expects
                  TextMateHelper.should_not_receive('create_and_open_file')
                  # when
                  @story_helper.goto_alternate_file
                end
              end
              
            end
          end
          
          describe "#choose_alternate_file" do
            it "should list the primary step matcher and all referenced step matchers" do
              #implement
            end
            
            # it "should tell textmate to go to the current file (after user has chosen)" do
            #   TextMateHelper.stub!(:display_select_list).and_return(0)
            # 
            #   # expects
            #   TextMateHelper.should_receive('goto_file').with('/path/to/story/file', :line => 1, :column => 1)
            #   # when
            #   @story_helper.goto_alternate_file
            # end
            # 
            # it "should not tell textmate to go a file (if the user doesn't choose anything)" do
            #   TextMateHelper.stub!(:display_select_list).and_return(nil)
            # 
            #   # expects
            #   TextMateHelper.should_not_receive('goto_file')
            #   # when
            #   @story_helper.goto_alternate_file
            # end
            
          end

          describe "and the current line doesn't contain a step" do
            before(:each) do
              @helper_file.stub!(:step_information_for_line).and_return(nil)
            end
            
            it "should not tell textmate to do anything" do
              # expect
              TextMateHelper.should_not_receive('goto_file')
              # when
              @story_helper.goto_current_step(1)
            end
          end
          
          describe "and the current line contains a step" do
            before(:each) do
              @helper_file.stub!(:step_information_for_line).and_return({:step_type => 'Given', :step_name => 'blah'})
            end
                          
            describe "and the step exists" do
              before(:each) do
                @helper_file.stub!(:location_of_step).and_return({:file_path => '/foo/bar', :line => 10, :column => 3})
              end
              
              it "should tell textmate to goto the file where the step is defined" do
                # expects
                TextMateHelper.should_receive('goto_file').with('/foo/bar', {:line => 10, :column => 3})
                # when
                @story_helper.goto_current_step(1)
              end
            end
            
            describe "and the step doesn't exist" do
              before(:each) do
                @helper_file.stub!(:location_of_step).and_return(nil)
              end
              
              it "should tell textmate to goto the story's step file and to insert the step" do
                # expects
                TextMateHelper.should_receive('goto_file').with('/path/to/steps/file', {:line => 2, :column => 1})
                TextMateHelper.should_receive('insert_text')
                # when
                @story_helper.goto_current_step(1)
              end
            end
          end
        end
        
        describe "in a step matcher file" do
          before(:each) do
            @helper_file.stub!(:is_step_file?).and_return(true)
          end

          describe "when the step matcher has a single alternate_file" do
            before(:each) do
              @helper_file.stub!(:alternate_file_path).and_return("/path/to/storyone.story")
              @helper_file.stub!(:alternate_files_and_names).and_return([
                  {:name => 'storyone', :file_path => "/path/to/storyone.story"}
              ])
            end
            
            describe "#go_to_alternate_file" do
              it "should go to the story" do
                # expects
                TextMateHelper.should_receive('goto_file').with('/path/to/storyone.story', :line => 1, :column => 1)
                # when
                @story_helper.goto_alternate_file
              end
            end
            
            describe "#choose_alternate_file" do
              it "should list the story" do
                # expects
                TextMateHelper.should_receive('display_select_list').with(['storyone'])
                # when
                @story_helper.choose_alternate_file
              end
            end
          end
          
          describe "when the step matcher is used by multiple stories" do
            before(:each) do
              @helper_file.stub!(:alternate_file_path).and_return(nil)
              @helper_file.stub!(:alternate_files_and_names).and_return([
                {:name => 'storyone', :file_path => "/path/to/storyone.story"},
                {:name => 'storytwo', :file_path => "/path/to/storytwo.story"}
              ])
            end
            
            describe "#go_to_alternate_file" do
              it "should list the stories using this step matcher" do
                # expects
                TextMateHelper.should_receive('display_select_list').with(['storyone', 'storytwo'])
                # when
                @story_helper.goto_alternate_file
              end
            end
            
            describe "#choose_alternate_file" do
              it "should list the stories using this step matcher" do
                # expects
                TextMateHelper.should_receive('display_select_list').with(['storyone', 'storytwo'])
                # when
                @story_helper.choose_alternate_file
              end
            end
          end
          
          describe "when the step matcher is not used by any stories" do
            before(:each) do
              @helper_file.stub!(:alternate_file_path).and_return(nil)
              @helper_file.stub!(:alternate_files_and_names).and_return([])
            end
            
            describe "#go_to_alternate_file" do
              it "should do nothing" do
                # expects
                TextMateHelper.should_not_receive('goto_file')
                TextMateHelper.should_not_receive('display_select_list')
                # when
                @story_helper.goto_alternate_file
              end
            end

            describe "#choose_alternate_file" do
              it "should do nothing" do
                # expects
                TextMateHelper.should_not_receive('goto_file')
                TextMateHelper.should_not_receive('display_select_list')
                # when
                @story_helper.choose_alternate_file
              end
            end
          end

          describe "#goto_current_step" do
            it "should not tell textmate to do anything" do
              # expects
              TextMateHelper.should_not_receive('display_select_list')
              TextMateHelper.should_not_receive('goto_file')
              # when
              @story_helper.goto_current_step(1)
            end
          end
        end        
####        
        describe "#choose_alternate_file" do
          # it "should prompt the user to choose a step file from those included in the runner" do
          #   # expects
          #   TextMateHelper.should_receive('display_select_list').with(['one', 'two'])
          #   # when
          #   @story_helper.choose_alternate_file
          # end
          
          # it "should tell textmate to open the chosen file (after a user has selected)" do
          #   TextMateHelper.stub!(:display_select_list).and_return(0)
          #   
          #   # expects
          #   TextMateHelper.should_receive('goto_file').with("/path/to/one", :line => 1, :column => 1)
          #   # when
          #   @story_helper.choose_alternate_file
          # end
        end      
      end
    end
  end
end