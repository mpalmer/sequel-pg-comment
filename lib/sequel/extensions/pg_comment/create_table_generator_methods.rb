#:nodoc:
# Enhancements to the standard schema modification methods in a
# block-form `create_table` method, to support setting comments via the
# `:comment` option.
#
module Sequel::Postgres::Comment::CreateTableGeneratorMethods
	# An array of all the comments that this generator has seen fit to
	# create.
	#
	# @return [Array<SqlGenerator>]
	#
	attr_reader :comments

	include Sequel::Postgres::Comment

	# Enhanced version of the `column` table definition method, which
	# supports setting a comment on the column.
	#
	# @option [String] :comment The comment to set on the column that is
	#   being defined.
	#
	def column(*args)
		super

		if args.last.is_a?(Hash) && args.last[:comment]
			comments << SqlGenerator.create(:column, args.first, args.last[:comment])
		end
	end

	# Enhanced version of the `primary_key` table definition method, which
	# supports setting a comment on either the column or constraint.
	#
	# If the primary key is composite (`name` is an array), then the comment
	# will be placed on the index.  Otherwise, the comment will be set
	# on the column itself.
	#
	# @option [String] :comment The comment to set on the column or
	#   index that is being defined.
	#
	def primary_key(name, *args)
		if args.last.is_a?(Hash) && args.last[:comment] and !name.is_a? Array
			# The composite primary key case will be handled by the
			# `composite_primary_key` method, so we don't have to deal with it
			# here.
			comments << SqlGenerator.create(:column, name, args.last[:comment])
		end
				
		super
	end

	# Enhanced version of the `composite_primary_key` table definition method,
	# which supports setting a comment on the primary key index.
	#
	# @option [String] :comment The comment to set on the primary key index.
	#
	def composite_primary_key(columns, *args)
		if args.last.is_a?(Hash) and args.last[:comment]
			if args.last[:name]
				comments << SqlGenerator.create(
				              :index,
				              args.last[:name],
				              args.last[:comment]
				            )
			else
				comments << PrefixSqlGenerator.new(:index, :_pkey, args.last[:comment])
			end
		end

		super
	end

	# Enhanced version of the `composite_foreign_key` table definition method,
	# which supports setting a comment on the FK constraint.
	#
	# @option [String] :comment The comment to set on the foreign key constraint.
	#
	def composite_foreign_key(columns, opts)
		if opts.is_a?(Hash) and opts[:comment] and opts[:table]
			if opts[:name]
				comments << SqlGenerator.create(
				              :constraint,
				              opts[:name],
				              opts[:comment]
				            )
			else
				comments << SqlGenerator.create(
				              :constraint,
				              "#{opts[:table]}_#{columns.first}_fkey".to_sym,
				              opts[:comment]
				            )
			end
		end

		super
	end

	# Enhanced version of the `index` table definition method,
	# which supports setting a comment on the index.
	#
	# @option [String] :comment The comment to set on the index that is being
	#   defined.
	#
	def index(columns, opts = OPTS)
		if opts[:comment]
			if opts[:name]
				comments << SqlGenerator.create(:index, opts[:name], opts[:comment])
			else
				comments << PrefixSqlGenerator.new(
				              :index,
				              ("_" + [columns].flatten.map(&:to_s).join('_') + "_index").to_sym,
				              opts[:comment]
				            )
			end
		end
		
		super
	end

	# Enhanced version of the `unique` table definition method,
	# which supports setting a comment on the unique index.
	#
	# @option [String] :comment The comment to set on the index that will be
	#   defined.
	#
	def unique(columns, opts = OPTS)
		if opts[:comment]
			if opts[:name]
				comments << SqlGenerator.create(:index, opts[:name], opts[:comment])
			else
				comments << PrefixSqlGenerator.new(
				              :index,
				              ("_" + [columns].flatten.map(&:to_s).join('_') + "_key").to_sym,
				              opts[:comment]
				            )
			end
		end
		
		super
	end

	# Enhanced version of the `constraint` table definition method,
	# which supports setting a comment on the constraint.
	#
	# @option [String] :comment The comment to set on the constraint that is
	#   being defined.
	#
	def constraint(name, *args, &block)
		opts = name.is_a?(Hash) ? name : (args.last.is_a?(Hash) ? args.last : {})
		
		if opts[:comment]
			if name
				comments << SqlGenerator.create(:constraint, name, opts[:comment])
			else
				raise Sequel::Error,
				      "Setting comments on unnamed or check constraints is not supported"
			end
		end
	end
end
