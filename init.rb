require "attribute_searchable"

ActiveRecord::Base.send(:include, ActiveRecord::AttributeSearchable)
