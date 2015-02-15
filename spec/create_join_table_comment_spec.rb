require_relative 'spec_helper'
require 'sequel'

describe "#create_join_table" do
	let(:db) do
		Sequel.connect("mock://postgres").extension(:pg_comment)
	end

	it "sets a table comment" do
		db.create_join_table(
		  {
		    :category_id => :categories,
		    :term_id => :terms
		  },  
		  :comment => "HABTM FTW!"
		)
		expect(db.sqls.last).
		  to eq("COMMENT ON TABLE categories_terms IS 'HABTM FTW!'")
	end
end
