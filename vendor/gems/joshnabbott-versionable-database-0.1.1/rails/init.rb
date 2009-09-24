require 'versionable_database'
ActiveRecord::Base.instance_eval { include VersionableDatabase }