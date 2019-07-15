#ifndef TIE_INSERTER_H
#define TIE_INSERTER_H

template <typename String, typename Coordinate> struct TieInserter {
		
	using Chip=PlacementDataContainer<String,Coordinate>;
		
	using Row = typename PlacementDataContainer<String,Coordinate>::Row;
	
	using Macro = typename
		PlacementDataContainer<String,Coordinate>::Macro;
	
	using Instance = typename 
		PlacementDataContainer<String,Coordinate>::Instance;
	
	using YRowBatch = CoordVectorMap<Coordinate,Row>;
	
	using Result = 
		std::map<std::shared_ptr<const Macro>,std::vector<Instance>>;
	
	using Micron = class Micron<Coordinate>;

	auto getYRowBuckets(const Chip& data) const
	{
		std::map<decltype(Row::site),YRowBatch> rv;
		
		for(auto& row: getYXSortedRows(data))
		{
			rv[row->site][row->orig.y].push_back(row);
		}
		return rv;
	}
	
	auto getYXSortedRows(const Chip& data) const
	{
		PtrVector<Row> rv;
		rv.reserve(data.m.row.size());
		for(const auto& row:data.m.row) rv.push_back(row);
		std::stable_sort(rv.begin(),rv.end(),[](auto& r1,auto& r2) 
				-> bool {
			return *r1.get() < *r2.get();	
			});
		return rv;
	}

	void left(Result& r, std::shared_ptr<const Row> row,
		std::shared_ptr<const Macro>&& macro)
	{
		if(row->site!=macro->site) return;
		r[macro].emplace_back()={row->orig,row->ori};
	}
	
	void right(Result& r, std::shared_ptr<const Row> row,
		std::shared_ptr<const Macro>&& macro)
	{
		if(row->site!=macro->site) return;
		#define M(a,b) { Orientation:: a, Orientation:: b }
		static std::map<Orientation,Orientation> xmir
			{ M(N,FN),M(FN,N),M(S,FS),M(FS,S) };
		#undef M
		r[macro].emplace_back()={
			row.get()->orig+
				Point<Coordinate>({Coordinate(row->step.x)*
					(row->num.x)-macro->size.x.db_unit(),0}),
			xmir[row->ori]
			};
	}
	
	void spread(Result& r, std::shared_ptr<const Row> row,
		std::shared_ptr<const Macro>&& macro,
		const Coordinate shift, const Coordinate Spacing)
	{
		if(row->site!=macro->site) return;
		for(auto& p:row->spread(shift,Spacing))
		{
			r[macro].emplace_back()={p,row->ori};
		}
	}

	auto BoundaryCells(const Chip& chip) {
			Result R;
			
			const auto endcap = chip.config.tie.find(TIETYPE::ENDCAP);
			if(endcap!=chip.config.tie.end())
				for(const auto& row: chip.m.row)
					left(R,row,endcap->second), 
					right(R,row,endcap->second);
			return R;
		}
	
	auto CheckerBoard(const Chip& chip) {
			Result R;
			auto tie = chip.config.tie.find(TIETYPE::FILL);
			const Coordinate Spacing=
				Micron(chip.config.checkerBoardSpacing).db_unit();
			Coordinate 
				prevY=-1,
				// Workaround for popular EDA tool welltap bug
				rowInitialXShift1=Spacing/4, // alternatively, Spacing/2
				rowInitialXShift2=Spacing*3/4, // alternatively, Spacing
				xs=Spacing;
			if(tie!=chip.config.tie.end())
				for(const auto& row:getYXSortedRows(chip))
				{
					if(row->orig.y!=prevY)
					{
						prevY=row->orig.y;
						xs=(xs==rowInitialXShift1?
							rowInitialXShift2:
							rowInitialXShift1);
					}
					spread(R,row,tie->second,xs,Spacing);
				}

			return R;
		}
};

#endif//TIE_INSERTER_H
