require_relative 'spec_helper'
require 'sequel'

describe "#create_view" do
	let(:db) do
		Sequel.connect("mock://postgres").extension(:pg_comment)
	end

	it "sets a table comment on a view" do
		db.create_view(
		  :gold_albums,
		  db[:albums].where { copies_sold > 500_000 },
		  :comment => "Rich!"
		)
		expect(db.sqls.last).
		  to eq("COMMENT ON VIEW \"gold_albums\" IS 'Rich!'")
	end

	it "sets a table comment on a materialized view" do
		db.create_view(
			:gold_albums_mv,
			db[:albums].where { copies_sold > 500_000 },
			:comment => "Rich!",
			:materialized => true,
		)
		expect(db.sqls.last).
			to eq("COMMENT ON MATERIALIZED VIEW \"gold_albums_mv\" IS 'Rich!'")
	end
end
