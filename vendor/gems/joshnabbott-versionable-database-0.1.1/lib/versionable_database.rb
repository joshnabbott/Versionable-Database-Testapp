module VersionableDatabase
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def versionify(options = {})
      options.reverse_merge!(:version_directory => "#{RAILS_ROOT}/versions")
      send(:include, VersionableDatabase::InstanceMethods)
      after_destroy :version!
      after_save :version!

      self.instance_eval do
        def commit!(message = Time.now.to_s)
          response = `cd #{self.version_dir} && git add . && git commit -am '#{message}'`

          logger.debug("#### START VERSIONING ####")
          logger.debug(response)
          # logger.debug $?
          logger.debug("#### END VERSIONING ####")
        end

        def version
          File.open(self.version_file, 'w+') { |file| file.write(self.all.to_yaml) }
        end

        def version_dir
          @@version_dir
        end

        def version_dir=(directory)
          @@version_dir = directory
        end

        def version_dir_name
          @@version_dir_name
        end

        def version_dir_name=(directory_name)
          @@version_dir_name = directory_name
        end

        def version_file
          File.join(self.version_dir, self.class_name.tableize, self.version_file_name)
        end

        def version_file_name
          "#{self.class_name.tableize}.yml"
        end

        def unversion!
          File.delete(version_file)
          self.all.map(&:unversion!)
          self.commit!("No longer version controlling #{self.class_name}.")
        end

        private
          def create_version_directories!
            Dir.mkdir(self.version_dir) unless File.exists?(self.version_dir)
            Dir.mkdir(File.join(self.version_dir, self.class_name.tableize)) unless File.exists?(File.join(self.version_dir, self.class_name.tableize))
          end

          def initialize_git_repository!
            unless File.exists?(File.join(self.version_dir, '.git'))
              response = `cd #{self.version_dir} && git init`

              logger.debug("#### START INITIALIZING GIT REPOSITORY ####")
              logger.debug(response)
              # logger.debug $?
              logger.debug("#### END INITIALIZING GIT REPOSITORY ####")
            end
          end

          def setup_complete?
            File.exists?(self.version_dir) &&
            File.exists?(File.join(self.version_dir, self.class_name.tableize)) &&
            File.exists?(File.join(self.version_dir, '.git'))
          end

          # Create the necessary directories and files, along with initializing a new git repo when needed
          def setup!(options)
            self.version_dir      = options[:version_directory]
            self.version_dir_name = options[:version_directory].split('/').last
            unless setup_complete?
              create_version_directories!
              initialize_git_repository!
              STDOUT.puts "***************** IMPORTANT *****************"
              STDOUT.puts "Versionable has created a new direcotry in #{self.version_dir} where files will be written to and stored."
              STDOUT.puts "Since you may not want Git tracking the files Versionable creates, you may want to add #{self.version_dir_name}/* to your .gitignore file."
              STDOUT.puts "If you don't already have a .gitignore file in #{RAILS_ROOT} (#{File.exists?(File.join(RAILS_ROOT, '.gitignore')) ? "and you do" : "which you don't"}) you may want to create one now."
            end
          end
      end
      setup!(options)
    end
  end

  module InstanceMethods
    def version!
      self.class.version
      self.version
      self.class.commit!(calculate_commit_message)
    end

    def version
      File.open(self.version_file, 'w+') { |file| file.write(self.to_yaml) }
    end

    def version_file
      File.join(self.class.version_dir, self.class.class_name.tableize, version_file_name)
    end

    def version_file_name
      "#{self.class.class_name.downcase.underscore}-#{self.id}.yml"
    end

    def unversion!
      File.delete(version_file)
    end

    protected
      def calculate_commit_message
        # Using after_save and after_destroy means there are three possibilities:
        # The record was either inserted, updated, or deleted from the db.
        # We can find out if it was deleted by simply seeing if the record still exists in the db.
        # However, finding out whether the record was inserted or updated is trickier since Class#new_record? returns
        # false after save.
        # The best thing I came up with was checking to see if the instance variable @new_record is still hanging around for this instance
        # If it is, that means the record was just created. If it's not, it was updated.
        action = if !self.instance_variable_get("@new_record").nil?
          'Created'
        elsif !self.class.exists?(self.id)
          'Deleted'
        else
          'Updated'
        end
        "#{action} #{self.class.class_name}[#{self.id}]: #{Time.now.to_s(:db)}"
      end
  end
end