# Need to use the rspec in current project
# require 'rubygems'
# require 'spec'
# require 'spec/story'
require File.join(File.dirname(__FILE__), %w[.. .. mate])
require File.join(File.dirname(__FILE__), %w[.. text_mate_helper])
require File.join(File.dirname(__FILE__), 'files')
require File.join(File.dirname(__FILE__), 'text_mate_formatter')

module Spec
  module Mate
    module Story
      
      class StoryHelper
        
        unless const_defined? :TM_PROJECT_ROOT_PATH
          TM_PROJECT_ROOT_PATH = File.expand_path(ENV['TM_PROJECT_DIRECTORY'])

          STORIES_PATH        = "#{TM_PROJECT_ROOT_PATH}/stories"
          STEP_MATCHERS_PATH  = "#{TM_PROJECT_ROOT_PATH}/stories/steps"
          HELPER_PATH         = "#{TM_PROJECT_ROOT_PATH}/stories/helper"
        end
        
        def initialize(full_file_path)
          @full_file_path = full_file_path
          @file = Files::Base.create_from_file_path(full_file_path)
        end
        
        def run_story
          argv = ""
          argv << '--format'
          argv << '=Spec::Mate::Story::TextMateFormatter'
          argv += ENV['TM_RSPEC_STORY_OPTS'].split(" ") if ENV['TM_RSPEC_STORY_OPTS']
          $rspec_options = Spec::Runner::OptionParser.parse(argv, STDERR, STDOUT)
          
          run_story_files([@file.full_file_path])
        end
        
        def goto_alternate_file
          if @file.alternate_file_path.nil?
            choose_alternate_file
          else
            goto_or_create_file(@file.alternate_file_path)
          end
        end
        
        def choose_alternate_file
          alternate_files_and_names = @file.alternate_files_and_names
          return if alternate_files_and_names.empty?
          if (choice = TextMateHelper.display_select_list(alternate_files_and_names.collect{|h| h[:name]}))
            goto_or_create_file(alternate_files_and_names[choice][:file_path])
          end
        end
        
        def goto_current_step(line_number)
          return unless @file.is_story_file? && step_info = @file.step_information_for_line(line_number)
          if (step_location = @file.location_of_step(step_info))
            TextMateHelper.goto_file(step_location.delete(:file_path), step_location)
          else
            goto_steps_file_with_new_steps([step_info])
          end
        end
        
        def create_all_undefined_steps
          return unless @file.is_story_file? && undefined_steps = @file.undefined_steps
          goto_steps_file_with_new_steps(undefined_steps)
        end
        
      protected
        def goto_steps_file_with_new_steps(new_steps)
          goto_or_create_file(@file.primary_steps_file_path, :line => 2, :column => 1, :additional_content => Files::StepsFile.create_steps(new_steps, false))
        end
        
        def request_confirmation_to_create_file(file_path)
          TextMateHelper.request_confirmation(:title => "Create new file?", :prompt => "Do you want to create\n#{file_path.gsub(/^(.*?)stories/, 'stories')}?")
        end
        
        def goto_or_create_file(file_path, options = {})
          options = {:line => 1, :column => 1}.merge(options)
          additional_content = options.delete(:additional_content)
          
          if File.file?(file_path)
            TextMateHelper.goto_file(file_path, options)
            TextMateHelper.insert_text(additional_content) if additional_content
          elsif request_confirmation_to_create_file(file_path)
            TextMateHelper.create_and_open_file(file_path)
            TextMateHelper.insert_text(default_content(file_path, additional_content))
          end
        end
        
        def silently_create_file(file_path)
          TextMateHelper.create_file(file_path)
          `echo "#{Files::Base.create_from_file_path(file_path).class.default_content(file_path).gsub('"','\\"')}" > "#{file_path}"`
        end
        
        def default_content(file_path, additional_content)
          Files::Base.default_content_for(file_path, additional_content)
        end
        
        def run_story_files(stories)
          clean_story_paths(stories).each do |story|
            setup_and_run_story(File.readlines("#{STORIES_PATH}/#{story}.story"), story)
          end
        end
        
        def clean_story_paths(paths)
          paths.reject! { |path| path =~ /^-/ }
          paths.map! { |path| File.expand_path(path) }
          paths.map! { |path| path.gsub(/\.story$/, "") }
          paths.map! { |path| path.gsub(/#{STORIES_PATH}\//, "") }
        end
        
        def setup_and_run_story(lines, story_name)
          require HELPER_PATH

          steps = steps_for_story(story_name)
          steps.reject! { |step| !File.exist?("#{STEP_MATCHERS_PATH}/#{step}.rb") }
          steps.each    { |step| require "#{STEP_MATCHERS_PATH}/#{step}" }

          run_story_with_steps(lines, steps)
        end
        
        def steps_for_story(story_name)
          story_name.to_s.split("/")
        end
        
        def run_story_with_steps(lines, steps)
          tempfile = Tempfile.new("story")
          lines.each do |line|
            tempfile.puts line
          end
          tempfile.close

          with_steps_for(*steps.map(&:to_sym)) do
            run tempfile.path, :type => RailsStory
          end
        end
      end
      
    end
  end
end