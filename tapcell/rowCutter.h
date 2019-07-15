#ifndef ROW_CUTTER_H
#define ROW_CUTTER_H

template <typename String, typename Coordinate> struct RowCutter {
	using Row = typename PlacementDataContainer<String,Coordinate>::Row;
	using PtrRow = std::shared_ptr<Row>;
	using RowBatch = CoordVectorMap<Coordinate,Row>;
	using Rows = PtrVector<Row>;
	
	struct {
		bool dirty: 1 {false};
		} m;
	
	void leftOf(Rows& rows, PtrRow R, Coordinate X){
		auto Width=X-R->orig.x-R->site->size.x.db_unit();
		R->num.x=decltype(R->step.x)(Width) / R->step.x;
		R->name+="_L";
		m.dirty=true;
		}
		
	 void rightOf(Rows& rows, PtrRow R, Coordinate X){
		auto shiftSteps=ceil((X-R->orig.x)/R->step.x);
		R->orig.x += shiftSteps*R->step.x;
		R->num.x -= shiftSteps;
		m.dirty=true;
		}
		
	void newRowRightOf(Rows& rows, PtrRow R, Coordinate X){
		rows.emplace_back() = std::make_shared<Row>();
		auto& newR = rows.back();
		*newR=*R;
		newR->name+="_R";
		rightOf(rows,newR,X);
		}
	
	void cut(Rows& rows, PtrRow R, const Rectangle<Coordinate>& Obs) {
		m.dirty=false;
		auto rowRect=R->bbox(); 
		if(rowRect.intersects(Obs))
		{
			const auto minRowWidth=2*
				(R->step.x+R->site->size.x.db_unit());
			if(rowRect.right()>minRowWidth+Obs.right()) {
 				if(rowRect.left()+minRowWidth<Obs.left())
						newRowRightOf(rows,R,Obs.right());
					else
						rightOf(rows,R,Obs.right());
				}
				
			if(rowRect.left()+minRowWidth<Obs.left())
				leftOf(rows,R,Obs.left());
		} else m.dirty=true; // don't touch, prevent deletion of row
	}

	// Clean up row overlaps for the same site for non-pristine DEF
	RowCutter(Rows& rows, RowBatch& r)
	{
		for(auto& pairCoordRows: r)
		{
			SetIndex(rows,&Row::index);
			auto yRowsIdx=DecreaseIndexOrder(pairCoordRows.second,&Row::index);
			for(auto rIdx: yRowsIdx)
			{
				for(auto idx: yRowsIdx)
				{
					if(rIdx==idx) continue;
					cut(rows,rows[rIdx],rows[idx]->bbox());
					if(!m.dirty) rows.erase(rows.begin()+rIdx);
				}
			}
		}
	}
	
	RowCutter(Rows& rows, const Rectangle<Coordinate>& r) 
	{
		for(size_t idx=0;idx<rows.size();idx++) {
			cut(rows,rows[idx],r);
			if(!m.dirty) rows.erase(rows.begin()+idx--);
			}
		}
	};
#endif//ROW_CUTTER_H
