require_relative 'spec_helper'
require 'sequel'

describe "#comment_for" do
	let(:db) do
		Sequel.connect("mock://postgres").extension(:pg_comment)
	end

	it "gets a table comment" do
		db.comment_for(:foo)
		expect(db.sqls).
		  to eq([%{SELECT obj_description(CAST('foo' AS regclass), 'pg_class') } +
		           %{AS \"comment\" LIMIT 1}])
	end

	it "gets a column comment" do
		db.comment_for(:foo__column)
		expect(db.sqls).
		  to eq([%{SELECT col_description("c"."oid", "a"."attnum") AS "comment" } +
		           %{FROM "pg_class" AS "c" } +
		           %{INNER JOIN "pg_attribute" AS "a" ON ("c"."oid" = "a"."attrelid") } +
		           %{WHERE (("c"."relname" = 'foo') AND ("a"."attname" = 'column')) LIMIT 1}
		       ])
	end

	it "gets a column comment via the dataset" do
		db[:foo].comment_for(:column)
		expect(db.sqls).
		  to eq([%{SELECT col_description("c"."oid", "a"."attnum") AS "comment" } +
		           %{FROM "pg_class" AS "c" } +
		           %{INNER JOIN "pg_attribute" AS "a" ON ("c"."oid" = "a"."attrelid") } +
		           %{WHERE (("c"."relname" = 'foo') AND ("a"."attname" = 'column')) LIMIT 1}
		       ])
	end
end
