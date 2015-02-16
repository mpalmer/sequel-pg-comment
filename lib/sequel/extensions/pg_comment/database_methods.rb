# Support for setting and retrieving comments on all object types
# in a PostgreSQL database.
#
module Sequel::Postgres::Comment::DatabaseMethods
	# Set the comment for a database object.
	#
	# @param type [#to_s] The type of object that you wish to comment on.
	#   This can either be a string or symbol.  Any object type that PgSQL
	#   knows about should be fair game.  The current list of object types
	#   that this plugin knows about (and hence will accept) is listed in
	#   the {Sequel::Postgres::Comment::OBJECT_TYPES} array.
	#
	# @param id [#to_s] The name of the object that you wish to comment on.
	#   For most types of object, this should be the literal name of the
	#   object.  However, for columns in a table or view, you should separate
	#   the table/view name from the column name with a double underscore
	#   (ie `__`).  This is the standard Sequel convention for such things.
	#
	# @param comment [String] The comment you wish to set for the database
	#   object.
	#
	# @see {Sequel::Postgres::Comment.normalise_comment} for details on
	#   how the comment string is interpreted.
	#
	def comment_on(type, id, comment)
		gen = begin
			Sequel::Postgres::Comment::SqlGenerator.create(type, id, comment)
		rescue ArgumentError
			raise ArgumentError,
					"Invalid object type: #{type.inspect}"
		end

		execute(gen.generate)
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
	# Enhanced version to support setting comments on objects created in a
	# block-form `create_table` statement.
	#
	def create_table_generator(&block)
		super do
			extend Sequel::Postgres::Comment::CreateTableGeneratorMethods
			@comments = []
			instance_eval(&block) if block
		end
	end

	#:nodoc:
	# Enhanced version to support setting comments on objects created in a
	# block-form `create_table` statement.
	#
	# If you're wondering why we override the
	# create_table_indexes_from_generator method, rather than
	# create_table_from_generator, it's because the indexes method runs last,
	# and we can only create our comments after the objects we're commenting
	# on have been created.  We *could* set some comments in
	# create_table_from_generator, and then set index comments in
	# create_table_indexes_from_generator, but why override two methods when
	# you can just override one to get the same net result?
	#
	def create_table_indexes_from_generator(name, generator, options)
		super

		generator.comments.each do |sql_gen|
			if sql_gen.respond_to? :table_name
				sql_gen.table_name = name
			end

			execute(sql_gen.generate)
		end
	end

	#:nodoc:
	# Enhanced version to support setting comments on objects created in a
	# block-form `alter_table` statement.
	#
	def alter_table_generator(&block)
		super do
			extend Sequel::Postgres::Comment::AlterTableGeneratorMethods
			@comments = []
			instance_eval(&block) if block
		end
	end

	#:nodoc:
	# Enhanced version to support setting comments on objects created in a
	# block-form `alter_table` statement.
	#
	def apply_alter_table_generator(name, generator)
		super

		generator.comments.each do |sql_gen|
			if sql_gen.respond_to?(:table_name=)
				sql_gen.table_name = name
			end

			execute(sql_gen.generate)
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

	# Quote an object name, handling the double underscore convention
	# for separating a column name from its containing object.
	#
	def quote_comment_identifier(id)
		id = id.to_s
		if id.index("__")
			tbl, col = id.split("__", 2)
			quote_identifier(tbl) + "." + quote_identifier(col)
		else
			quote_identifier(id)
		end
	end
end
