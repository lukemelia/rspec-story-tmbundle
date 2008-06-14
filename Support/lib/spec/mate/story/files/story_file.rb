module Spec
  module Mate
    module Story
      module Files
      
        class StoryFile < Base
          class << self
            def default_content(file_path, additional_content = nil)
              TextMateHelper.snippet_text_for('Story')
            end
          end
          
          def is_story_file?; true; end
          
          def name
            @name ||= full_file_path.match(/\/stories\/[^\.\/]*\/([^\.\/]*)\.story$/).captures.first
          end
          
          def theme
            @theme ||= full_file_path.match(/\/stories\/([^\.\/]*)\/[^\.\/]*\.story$/).captures.first
          end
          
          def alternate_file_path
            primary_steps_file_path
          end
          
          def primary_steps_file_path
            @primary_steps_file_path ||= full_file_path.gsub(%r</stories/#{theme}/#{name}\.story$>, "/stories/steps/#{theme}.rb")
          end
          
          # Steps file and included steps files
          def alternate_files_and_names
            [{:name => "#{theme.gsub('_', ' ')} steps", :file_path => primary_steps_file_path}] + primary_steps_file.referenced_step_files_and_names
          end
                    
          def step_information_for_line(line_number)
            line_index = line_number.to_i-1
            content_lines = File.read(full_file_path).split("\n")
            
            line_text = content_lines[line_index]
            return unless line_text && line_text.strip!.match(/^(given|when|then|and)(.*)/i)
            source_step_name = $2.strip
            
            step_type_line = content_lines[0..line_index].reverse.detect{|l| l.match(/^\s*(given|when|then)\s*(.*)$/i)}
            source_step_type = $1
            
            return {:step_type => source_step_type, :step_name => source_step_name}
          end
          
          # Right now will return first matching step
          def location_of_step(step_info)
            all_defined_steps.each do |step_def|
              return step_def if step_def[:type] == step_info[:step_type] && step_def[:step].matches?(step_info[:step_name])
            end
            return nil
          end
          
          def includes_step_file?(step_file_name)
            all_referenced_steps_files.any?{|steps_file| steps_file.name == step_file_name }
          end
          
          def undefined_steps
            undefined_steps = []
            all_steps_in_file.each do |step_info|
              undefined_steps << step_info unless location_of_step(step_info)
            end
            undefined_steps
          end
        protected
          def all_steps_in_file
            file_lines = File.read(full_file_path).split("\n").collect{|l| l.strip}
            
            text_steps = []
            step_type = 'unknown'
            file_lines.each do |line|
              step_type = $1 if line.match(/^(Given|When|Then)\s+/)
              text_steps << {:step_type => step_type, :step_name => $2} if line.match(/^(Given|When|Then|And)\s+(.*)$/)
            end
            
            text_steps
          end
          
          def all_defined_steps
            @defined_steps ||= gather_defined_steps
          end
          
          def primary_steps_file
            StepsFile.new(primary_steps_file_path)
          end
          
          def all_referenced_steps_files
            steps_files = [primary_steps_file]
            primary_steps_file.referenced_steps_files.each do |step_file|
              unless steps_files.include?(step_file)
                steps_files << step_file
                steps_files += step_file.referenced_steps_files
              end
            end
            steps_files
          end
          
          def gather_defined_steps
            all_referenced_steps_files.collect{ |step_file| step_file.step_definitions }.flatten
          end
        end
        
      end
    end
  end
end
