require_relative 'spec_helper'
require 'sequel'

describe "#comment_for" do
	let(:db) do
		Sequel.connect("mock://postgres").extension(:pg_comment)
	end

	it "gets a table comment" do
		db.comment_for(:foo)
		expect(db.sqls).
		  to eq(["SELECT obj_description('foo'::regclass, 'pg_class')"])
	end

	it "gets a column comment" do
		db.comment_for(:foo__column)
		expect(db.sqls).
		  to eq(["SELECT col_description(c.oid, a.attnum) " +
		          "FROM pg_class c " +
		          "JOIN pg_attribute a ON (c.oid=a.attrelid) " +
		          "WHERE c.relname='foo' AND a.attname='column'"
		       ])
	end

	it "gets a column comment via the dataset" do
		db[:foo].comment_for(:column)
		expect(db.sqls).
		  to eq(["SELECT col_description(c.oid, a.attnum) " +
		          "FROM pg_class c " +
		          "JOIN pg_attribute a ON (c.oid=a.attrelid) " +
		          "WHERE c.relname='foo' AND a.attname='column'"
		       ])
	end
end
