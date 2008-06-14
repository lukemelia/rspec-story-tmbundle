require 'rubygems'
require 'spec/story/step'

module Spec
  module Mate
    module Story
      module Files
      
        class StepsFile < Base
          class << self
            def default_content(file_path, additional_content = create_steps([:step_type => 'Given', :step_name => 'condition']))
              step_file_name = file_path.match(/([^\/]*)_steps.rb$/).captures.first
              %Q{steps_for(:${1:#{step_file_name}}) do\n#{additional_content}end\n}
            end
            
            def create_steps(steps_to_create, already_included_snippet_selection = true)
              sorted_steps = steps_to_create.inject({'Given' => [], 'When' => [], 'Then' => []}) do |steps_so_far, current_step_info|
                steps_so_far[current_step_info[:step_type]] << current_step_info[:step_name]
                steps_so_far
              end
              
              content = ""
              %w(Given When Then).each do |step_type|
                sorted_steps[step_type].each do |step_name|
                  step_name_text = already_included_snippet_selection ? step_name : "${1:#{step_name}}"
                  content += %Q{  #{step_type} "#{step_name_text}" do\n    pending\n  end\n  \n}
                  already_included_snippet_selection = true
                end
              end
              content
            end
          end
          
          def is_steps_file?; true; end
          
          def name
            @name ||= full_file_path.match(/\/([^\/]+)\.rb$/).captures.first
          end
          
          def alternate_file_path
            if story_files_and_names.length == 1
              story_files_and_names.first[:file_path]
            else
              nil
            end
          end
          
          def story_file_path
            @story_file_path ||= full_file_path.gsub(%r</steps/#{name}\.rb$>, "/#{name}/.*\.story")
          end
          
          # Story files which include this step file in the runner
          def story_files_and_names
            story_files = []
            Dir["#{project_root}/stories/**/*.story"].each do |file_path|
              sf = StoryFile.new(file_path)
              if sf.includes_step_file?(name)
                story_files << {:name => "#{sf.name.gsub('_', ' ')} story", :file_path => file_path}
              end
            end
            story_files.uniq
          end
          
          alias alternate_files_and_names story_files_and_names
          
          def referenced_steps_files
            referenced_step_names.collect do |name|
              StepsFile.new("#{project_root}/stories/steps/#{name}.rb")
            end
          end
          
          def referenced_step_files_and_names
             referenced_steps_files.collect{|sf| { :name => "#{sf.name.gsub('_', ' ')} steps", :file_path => sf.full_file_path}}
          end
          
          def step_definitions
            if File.file?(full_file_path)
              @steps = []
              @file_contents = File.read(full_file_path)
              eval(@file_contents)
              @steps
            else
              []
            end
          end
          
          def ==(other)
            other.full_file_path == self.full_file_path
          end
          
        protected
          # While evaluating step definitions code - This called when a new step has been parse
          # We need to save these to be able to match plain text 
          def add_step(type, pattern)
            step = Spec::Story::Step.new(pattern){raise "Step doesn't exist."}
            
            line_number = caller[1].match(/:(\d+)/).captures.first.to_i
            
            next_line = @file_contents.split("\n")[line_number]
            
            col_number =  if (md = next_line.match(/\s*[^\s]/))
                            md[0].length
                          elsif (md = next_line.match(/\s*$/))
                            md[0].length + 1
                          else
                            1
                          end
            
            @steps << {:step => step, :type => type, :pattern => pattern, :line => line_number + 1,
                        :column => col_number, :file_path => full_file_path, :group_tag => name}
          end
          
          def steps_for(*args)
            yield if block_given?
          end
          
          def include_steps_for(name)
          end
          
          
          def referenced_step_names
            if File.file?(full_file_path)
              content = File.read(full_file_path)
              include_steps_for_regexp = /.*include_steps_for\s+(.*)$/
              return [] unless content.match(include_steps_for_regexp)
              content.scan(include_steps_for_regexp).collect do |match|
                match.first.gsub(':','').split(/,\s*/)
              end.flatten
            else
              []
            end
          end
          
          def Given(pattern)
            add_step('Given', pattern)
          end

          def When(pattern)
            add_step('When', pattern)
          end

          def Then(pattern)
            add_step('Then', pattern)
          end
        end
        
      end
    end
  end
end
