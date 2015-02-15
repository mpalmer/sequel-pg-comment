#:nodoc:
# Enhancements to the standard schema modification methods in a
# block-form `alter_table` method, to support setting comments via the
# `:comment` option.
#
# Note that not every schema modification method is enhanced in this module;
# some modifications are implemneted in terms of more fundamental methods,
# and so do not require their own method here.  For example, `add_foreign_key`
# with a single column is handled by `add_column`, and so doesn't require its
# own implementation.  Rest assured that all schema modification methods
# *should* accept a `:comment` option, and set a comment in the database.  If
# you find one that doesn't, please file a bug.
#
module Sequel::Extension::PgComment::AlterTableGeneratorMethods
	attr_reader :comments

	include Sequel::Extension::PgComment

	# Enhanced version of the `add_column` schema modification method,
	# which supports setting a comment on the column.
	#
	# @option [String] :comment The comment to set on the column
	#   that is being added.
	#
	def add_column(*args)
		super

		if args.last.is_a?(Hash) && args.last[:comment]
			comments << SqlGenerator.create(:column, args.first, args.last[:comment])
		end
	end

	# Enhanced version of the `add_composite_primary_key` schema modification
	# method, which supports setting a comment on the index.
	#
	# @option [String] :comment The comment to set on the index that is being
	#   added.
	#
	def add_composite_primary_key(columns, opts)
		super

		if opts[:comment]
			comments << PrefixSqlGenerator.new(:index, :_pkey, opts[:comment])
		end
	end

	# Enhanced version of the `add_composite_foreign_key` schema modification
	# method, which supports setting a comment on the constraint.
	#
	# @option [String] :comment The comment to set on the constraint that is being
	#   added.
	#
	def add_composite_foreign_key(columns, table, opts)
		super
		
		if opts[:comment]
			comments << if opts[:name]
				SqlGenerator.create(:constraint, opts[:name], opts[:comment])
			else
				PrefixSqlGenerator.new(
			     :constraint,
			     "_#{columns.first}_fkey".to_sym,
			     opts[:comment]
			   )
			end
		end
	end

	# Enhanced version of the `add_index` schema modification method, which
	# supports setting a comment on the index.
	#
	# @option [String] :comment The comment to set on the index that is being
	#   added.
	#
	def add_index(columns, opts = OPTS)
		if opts[:comment]
			comments << if opts[:name]
				SqlGenerator.create(:index, opts[:name], opts[:comment])
			else
				PrefixSqlGenerator.new(
				  :index,
				  "_#{[columns].flatten.map(&:to_s).join("_")}_index".to_sym,
				  opts[:comment]
				)
			end
		end
	end

	# Enhanced version of the `add_constraint` schema modification method,
	# which supports setting a comment on the constraint.
	#
	# @option [String] :comment The comment to set on the constraint that is
	#   being added.
	#
	def add_constraint(name, *args, &block)
		super

		opts = args.last.is_a?(Hash) ? args.last : {}

		if opts[:comment]
			comments << SqlGenerator.create(:constraint, name, opts[:comment])
		end
	end

	# Enhanced version of the `add_unique_constraint` schema modification
	# method, which supports setting a comment on the index.
	#
	# @option [String] :comment The comment to set on the index that is being
	#   added.
	#
	def add_unique_constraint(columns, opts = OPTS)
		super

		if opts[:comment]
			comments << if opts[:name]
				SqlGenerator.create(:index, opts[:name], opts[:comment])
			else
				PrefixSqlGenerator.new(
			     :index,
			     "_#{[columns].flatten.map(&:to_s).join("_")}_key".to_sym,
			     opts[:comment]
			   )
			end
		end
	end
end
