# Support for retrieving column comments from a PostgreSQL database
# via a dataset.  For example:
#
#    DB[:foo_tbl].comment_for(:some_column)
#
# Will retrieve the comment for `foo_tbl.some_column`, if such a
# column exists.
#
module Sequel::Extension::PgComment::DatasetMethods
	# Retrieve the comment for the column named `col` in the "primary" table
	# for this dataset.
	#
	# @param col [#to_s] The name of the column for which to retrieve the
	#   comment.
	#
	# @return [String, NilClass] The comment defined for the column, or
	#   `nil` if there is no defined comment.
	#
	def comment_for(col)
		db.comment_for("#{first_source_table}__#{col}")
	end
end
