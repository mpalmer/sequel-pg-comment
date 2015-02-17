module Sequel::Postgres::Comment
	#:nodoc:
	# Generate SQL to set a comment.
	#
	class SqlGenerator
		# The PostgreSQL object types which this class knows how to generate
		# comment SQL for.
		#
		OBJECT_TYPES = %w{AGGREGATE
		                  CAST
		                  COLLATION
		                  CONVERSION
		                  DATABASE
		                  DOMAIN
								EXTENSION
								EVENT\ TRIGGER
								FOREIGN\ DATA\ WRAPPER
								FOREIGN\ TABLE
								FUNCTION
								INDEX
								LARGE\ OBJECT
								MATERIALIZED\ VIEW
								OPERATOR
								OPERATOR\ CLASS
								OPERATOR\ FAMILY
								PROCEDURAL\ LANGUAGE
								LANGUAGE
								ROLE
								SCHEMA
								SEQUENCE
								SERVER
								TABLE
								TABLESPACE
								TEXT\	SEARCH\ CONFIGURATION
								TEXT\ SEARCH\ DICTIONARY
								TEXT\ SEARCH\ PARSER
								TEXT\ SEARCH\ TEMPLATE
								TYPE
								VIEW
							}
		
		# Find the correct class for a given object type, and instantiate a
		# new one of them.
		#
		# @param object_type [String, Symbol] The type of object we're going
		#   to comment on.  Strings and symbols are both fine, and any case
		#   is fine, too.  Any underscores get turned into spaces.  Apart from
		#   that, it needs to be the exact name that PostgreSQL uses for the given
		#   type.
		#
		# @param object_name [String, Symbol] The name of the database object to
		#   set the comment on.  A string is considered "already quoted", and hence
		#   is not escaped any further.  A symbol is run through the usual Sequel
		#   identifier escaping code before being unleashed on the world.
		#
		# @param comment [String] The comment to set.
		#
		# @return [SqlGenerator] Some sort of `SqlGenerator` object, or a subclass.
		#
		# @raise [Sequel::Error] if you passed in an `object_type` that we don't
		#   know about.
		#
		def self.create(object_type, object_name, comment)
			generators.each do |gclass|
				if gclass.handles?(object_type)
					return gclass.new(object_type, object_name, comment)
				end
			end

			raise Sequel::Error,
			      "Unrecognised object type #{object_type.inspect}"
		end

		# Return whether or not this class supports the specified object type.
		#
		# @param object_type [String, Symbol] @see {.create}
		#
		# @return [TrueClass, FalseClass] whether or not this class can handle
		#   the object type you passed.
		#
		def self.handles?(object_type)
			self.const_get(:OBJECT_TYPES).include?(object_type.to_s.upcase.gsub('_', ' '))
		end

		private

		# Return all known `SqlGenerator` classes.
		#
		def self.generators
			@generators ||= ObjectSpace.each_object(Class).select do |klass|
				klass.ancestors.include?(self)
			end
		end

		# We just need this so we can quote things.
		def self.mock_db
			@mock_db ||= Sequel.connect("mock://postgres")
		end

		public

		# The canonicalised string (that is, all-uppercase, with words
		# separated by spaces) for the object type of this SQL generator.
		#
		attr_reader :object_type
		
		# The raw (might-be-a-symbol, might-be-a-string) object name that
		# was passed to us originally.
		#
		attr_reader :object_name
		
		# The comment.
		attr_reader :comment

		# Spawn a new SqlGenerator.
		#
		# @see {.create}
		#
		def initialize(object_type, object_name, comment)
			@object_type = object_type.to_s.upcase.gsub('_', ' ')
			@object_name = object_name
			@comment     = comment
		end

		# SQL to set a comment on the object of our affection.
		#
		# @return [String] The SQL needed to set the comment.
		#
		def generate
			quoted_object_name = case object_name
			when Symbol
				literal object_name
			else
				object_name
			end
				
			"COMMENT ON #{object_type} #{quoted_object_name} IS #{literal comment.to_s}"
		end

		private

		# Quote the provided database object (a symbol) or string value
		# (a string).
		#
		def literal(s)
			self.class.mock_db.literal(s)
		end
	end

	#:nodoc:
	# A specialised generator for object types that live "inside" a
	# table.  Specifically, those types are columns, constraints,
	# rules, and triggers.
	#
	# They get their own subclass because these object types can be
	# manipulated inside a `create_table` or `alter_table` block, and at the
	# time the block is evaluated, the code doesn't know the name of the
	# table in which they are contained.  So, we just stuff what we *do* know
	# into these generators, and then when all's done, we can go to each of
	# these generators, say "this is your table name", and then ask for the
	# generated SQL.
	#
	class TableObjectSqlGenerator < SqlGenerator
		# The few object types that this class handles.
		OBJECT_TYPES = %w{COLUMN CONSTRAINT RULE TRIGGER}

		# The name of the object which contains the object which is the direct
		# target of this SQL generator.  Basically, it's the table name.
		attr_accessor :table_name

		# Overridden constructor to deal with the double-underscore-separated
		# names that we all know and love.
		#
		# @see {SqlGenerator#initialize}
		#
		def initialize(object_type, object_name, comment)
			super

			if object_name.is_a?(Symbol) and object_name.to_s.index("__")
				@table_name, @object_name = object_name.to_s.split("__", 2).map(&:to_sym)
			end
		end

		# Generate special SQL.
		#
		# @see {SqlGenerator#generate}
		#
		def generate
			if table_name.nil?
				raise Sequel::Error,
				      "Cannot generate SQL for #{object_type} #{object_name} " +
				        "without a table_name"
			end

			qualified_object_name = case object_type
			when "COLUMN"
				"#{maybe_escape table_name}.#{maybe_escape object_name}"
			when "CONSTRAINT", "RULE", "TRIGGER"
				"#{maybe_escape object_name} ON #{maybe_escape table_name}"
			end
			
			"COMMENT ON #{object_type} #{qualified_object_name} IS #{literal comment}"
		end

		private
		
		# Handle with the vagaries of having both strings and symbols as
		# possible names -- we escape symbols, but leave strings to their own
		# devices.
		#
		def maybe_escape(s)
			Symbol === s ? literal(s) : s
		end
	end

	#:nodoc:
	# This is an annoying corner-case generator -- it doesn't handle any
	# types by default, but it will handle any *other* type where the name of
	# a table needs to be prefixed by a name.  The only known use case for
	# this at present is "implicit" (that is, automatically generated by the
	# database) constraints and indexes that get prefixed by the table name,
	# and which are generated at a time when the calling code doesn't know the
	# name of the table that it is generating SQL for.
	#
	class PrefixSqlGenerator < SqlGenerator
		# This class doesn't handle any object types directly, and must be
		# instantiated directly when needed
		OBJECT_TYPES = %w{}

		# The name of the table which should be prefixed to the object name
		# that was specified when this instance was created.
		#
		attr_accessor :table_name

		# Generate super-dooper special SQL.
		#
		# @see {SqlGenerator#generate}
		#
		def generate
			if table_name.nil?
				raise Sequel::Error,
				      "Cannot generate SQL for #{object_type} #{object_name} " +
				        "without a table_name"
			end

			prefixed_object_name = "#{table_name}#{object_name}"
			
			if Symbol === table_name || Symbol === object_name
				prefixed_object_name = prefixed_object_name.to_sym
			end

			g = SqlGenerator.create(object_type, prefixed_object_name, comment)
			g.table_name = table_name if g.respond_to? :table_name
			g.generate
		end
	end
end
