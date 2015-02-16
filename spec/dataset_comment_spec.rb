require_relative 'spec_helper'
require 'sequel'

describe "Dataset#comment" do
	let(:db) { Sequel.connect("mock://postgres").extension(:pg_comment) }

	it "gets the comment for the table" do
		db[:foo].comment
		expect(db.sqls).
		  to eq([%{SELECT obj_description(CAST('foo' AS regclass), 'pg_class') } +
		           %{AS "comment" LIMIT 1}])
	end

	it "gets the comment for the first table" do
		db[:foo].join(:bar, :id => :bar_id).where { foo__id < 20 }.comment
		expect(db.sqls).
		  to eq([%{SELECT obj_description(CAST('foo' AS regclass), 'pg_class') } +
		           %{AS "comment" LIMIT 1}])
	end
end
