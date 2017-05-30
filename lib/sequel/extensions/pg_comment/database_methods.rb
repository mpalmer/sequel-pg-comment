# Support for setting and retrieving comments on all object types
# in a PostgreSQL database.
#
module Sequel::Postgres::Comment::DatabaseMethods
	# @param type [Symbol] The object type you're looking to set the comment
	#   on.  This is just the PostgreSQL type name, lowercased, with spaces
	#   replaced with underscores.
	#
	# @param id [Symbol, String, Array<Symbol, String>] The identifier of the
	#   object that you wish to comment on.  For most types of object, this
	#   should be the literal name of the object.  However, for objects which
	#   are "contained" in another object (columns in tables/views, and
	#   constraints, triggers, and rules in tables) you must pass the
	#   identifier as a two-element array, where the first element is the
	#   container table or view, and the second element is the contained
	#   object (column, constraint, rule, or trigger).
	#
	#   In any event, when a `Symbol` is encountered, it is quoted for
	#   safety, and split into a schema and object name pair, if appropriate.
	#   If a `String` is passed, then **no escaping or quoting is done**.
	#   While this is a slight risk, it is necessary to allow you to
	#   reference complex object names which can't reasonably be described
	#   otherwise (`FUNCTION`, I'm looking at you).
	#
	# @param comment [String] The comment you wish to set for the database
	#   object.
	#
	# @raise [Sequel::Error] if the specified `type` isn't recognised.
	#
	# @see {Sequel::Postgres::Comment.normalise_comment} for details on
	#   how the comment string is interpreted.
	#
	def comment_on(type, id, comment)
		if Sequel::Postgres::Comment::STANDALONE_TYPES.include?(type)
			comment_on_standalone_type(type, id, comment)
		elsif Sequel::Postgres::Comment::CONTAINED_TYPES.include?(type)
			comment_on_contained_type(type, id, comment)
		else
			raise Sequel::Error,
			      "Unknown object type: #{type.inspect}"
		end
	end


	# Retrieve the comment for a database object.
	#
	# @param object [#to_s] The name of the database object to retrieve.  For
	#   most objects, this should be the literal name of the object.
	#   However, for columns on tables and views, the name of the table/view
	#   should be a separated from the name of the column by a double
	#   underscore (ie `__`).
	#
	# @return [String, NilClass] The comment on the object, or `nil` if no
	#   comment has been defined for the object.
	#
	def comment_for(object)
		object = object.to_s

		if object.index("__")
			tbl, col = object.split("__", 2)

			(select(Sequel.function(:col_description, :c__oid, :a__attnum).as(:comment)).
			   from(Sequel.as(:pg_class, :c)).
			   join(Sequel.as(:pg_attribute, :a), :c__oid => :a__attrelid).
			   where(:c__relname => tbl).
			   and(:a__attname => col).first || {})[:comment]
		else
			(select(
			   Sequel.function(
			     :obj_description,
			     Sequel.cast(object, :regclass),
			     "pg_class"
			   ).as(:comment)
			 ).first || {})[:comment]
		end
	end

	# An enhanced form of the standard `create_table` method, which supports
	# setting a comment in the `create_table` call when the `:comment` option
	# is provided.
	#
	# @option [String] :comment The comment to set on the newly-created table.
	#
	# @see [Sequel::Database#create_table](http://sequel.jeremyevans.net/rdoc/classes/Sequel/Database.html#method-i-create_table)
	#
	def create_table(*args)
		super

		if args.last.is_a?(Hash) && args.last[:comment]
			comment_on(:table, args.first, args.last[:comment])
		end
	end

	#:nodoc:
	# Enhanced to support creating comments on columns, after the table
	# itself (and hence all its columns) have been created.
	#
	def create_table_from_generator(name, generator, options)
		super

		generator.columns.each do |col|
			if col[:comment]
				comment_on(:column, [name, col[:name]], col[:comment])
			end
		end

		generator.constraints.each do |c|
			if c[:type] == :check && c[:name].nil?
				raise Sequel::Error,
				      "Setting comments on unnamed check constraints is not supported"
			end

			next unless c[:comment]

			case c[:type]
			when :primary_key
				c_name = c[:name] || "#{name}_pkey".to_sym
				comment_on(:index, c_name, c[:comment])
			when :foreign_key, :check
					c_name = c[:name] || "#{name}_#{c[:columns].first}_fkey".to_sym
					comment_on(:constraint, [name, c_name], c[:comment])
			when :unique
				c_name = c[:name] || ([name] + c[:columns] + ["key"]).join("_").to_sym
				comment_on(:index, c_name, c[:comment])
			end
		end
	end

	#:nodoc:
	# Enhanced to support creating comments on indexes, after the indexes
	# themselves have been created.
	#
	def create_table_indexes_from_generator(name, generator, options)
		super

		generator.indexes.each do |idx|
			if idx[:comment]
				i_name = idx[:name] || ([name] + idx[:columns] + ["index"]).join("_").to_sym
				comment_on(:index, i_name, idx[:comment])
			end
		end
	end

	#:nodoc:
	# Enhanced version to support setting comments on objects created in a
	# block-form `alter_table` statement.
	#
	def apply_alter_table_generator(name, generator)
		super

		schema, table = schema_and_table(name)
		fqtable = [schema, table].compact.map { |e| literal e.to_sym }.join('.')

		generator.operations.each do |op|
			if op[:comment]
				case op[:op]
				when :add_column
					comment_on(:column, [name, op[:name]], op[:comment])
				when :add_constraint
					case op[:type]
					when :primary_key
						comment_on(:index, "#{name}_pkey".to_sym, op[:comment])
					when :foreign_key, :check
						c_name = op[:name] || "#{name}_#{op[:columns].first}_fkey".to_sym
						comment_on(:constraint, [name, c_name], op[:comment])
					when :unique
						c_name = op[:name] || ([name] + op[:columns] + ["key"]).join("_").to_sym
						comment_on(:index, c_name, op[:comment])
					end
				when :add_index
					c_name = op[:name] || ([name] + op[:columns] + ["index"]).join("_").to_sym
					comment_on(:index, c_name, op[:comment])
				end
			end
		end
	end

	# An enhanced form of the standard `create_view` method, which supports
	# setting a comment in the `create_view` call when the `:comment` option
	# is provided.
	#
	# @option [String] :comment The comment to set on the newly-created view.
	#
	# @see [Sequel::Database#create_view](http://sequel.jeremyevans.net/rdoc/classes/Sequel/Database.html#method-i-create_view)
	#
	def create_view(*args)
		super

		if args.last.is_a?(Hash) && args.last[:comment]
			comment_on(:view, args.first, args.last[:comment])
		end
	end

	private

	def comment_on_standalone_type(type, id, comment)
		run "COMMENT ON #{type.to_s.gsub("_", " ").upcase} #{quoted_schema_and_table id} IS #{literal comment}"
	end

	def comment_on_contained_type(type, id, comment)
		unless id.is_a?(Array) and id.length == 2
			raise Sequel::Error,
			      "Invalid ID for #{type.inspect}: must be a two-element array"
		end

		fqtable = quoted_schema_and_table(id[0])
		fqname  = if id[1].is_a?(Symbol)
			quote_identifier id[1]
		elsif id[1].is_a?(String)
			id[1]
		else
			raise Sequel::Error,
			      "Invalid type for object ID: must be a Symbol or String"
		end

		if type == :column
			run "COMMENT ON COLUMN #{fqtable}.#{fqname} IS #{literal comment}"
		else
			run "COMMENT ON #{type.to_s.gsub("_", " ").upcase} #{fqname} ON #{fqtable} IS #{literal comment}"
		end
	end

	def quoted_schema_and_table(id)
		if id.is_a?(Symbol)
			literal id
		elsif id.is_a?(String)
			id
		else
			raise Sequel::Error,
			      "Invalid type for ID: #{id.inspect} (must by symbol or string)"
		end
	end
end
