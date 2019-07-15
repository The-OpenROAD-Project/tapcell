#include <map>
#include <string>
#include <vector>
#include <memory>
#include <set>
#include "tapcell.h"
#include "model.h"

using namespace Openroad::PowerDistributionNetwork;

template <typename String, typename Coordinate> class SpecialCellPlacer :
	public AbstractBridge<String,Coordinate>, 
	protected PlacementDataContainer<String,Coordinate>
{
	using AbstractBridge<String,Coordinate>::m_bridge;
	
	using Site = typename PlacementDataContainer<String,Coordinate>::Site;
	using Macro = typename PlacementDataContainer<String,Coordinate>::Macro;
	using Inst = typename PlacementDataContainer<String,Coordinate>::Instance;
	using Row = typename PlacementDataContainer<String,Coordinate>::Row;
	using RowBatch = CoordVectorMap<Coordinate,Row>;
	using Obs = typename PlacementDataContainer<String,Coordinate>::
									PlacementObstruction;
	using Micron = class Micron<Coordinate>;
	
	public:
		
		int init() override {
			
			if(SpecialCellPlacer::m_bridge) 
			{
				throw std::runtime_error("Singleton double initialization");
				return 0;
			}
			
			SpecialCellPlacer::m_bridge = SpecialCellPlacer::shared_from_this();
			return 1;
		}
			
		int createRow(
			String row, 
			String site,
			Coordinate origX, Coordinate origY,
			Orientation ori,
			int numX, int numY,
			int stepX, int stepY) override {
				auto pSite=this->ref.site.find(site);
				if(pSite==this->ref.site.end()) return 0;
				auto& newRowPtr=this->m.row.emplace_back();
				newRowPtr=std::make_shared<Row>();
				*newRowPtr={row,ori,
					{origX,origY},{numX,numY},{stepX,stepY},pSite->second};
				this->ref.row[row]=newRowPtr;
				return 1;
			}
		
		int createSite(
			String name,
			Coordinate x, Coordinate y,
			Symmetry symmetry 
		) override {
				auto& newSitePtr=this->m.site.emplace_back();
				newSitePtr=std::make_shared<Site>();
				*newSitePtr={name,{x,y},symmetry};
				this->ref.site[name]=newSitePtr;
				return 1;
			}

		int createMacro(
			String name,
			String site,
			Coordinate ox,Coordinate oy, 
			Coordinate x,Coordinate y,
			const std::vector<Symmetry>& vsym) override {
				auto pSite=this->ref.site.find(site);
				// Hard Macro may not have a site, inserting NULL for them
				auto& newMacroPtr=this->m.macro.emplace_back();
				newMacroPtr=std::make_shared<Macro>();
				*newMacroPtr.get()={name,{ox,oy},{x,y},
					std::set<Symmetry>(vsym.begin(),vsym.end()),
					pSite==this->ref.site.end()?NULL:pSite->second};
				this->ref.macro[name]=newMacroPtr;
				return 1;
			}
			
		int createInst(
			String name,
			String macro,
			Coordinate x, Coordinate y,
			Orientation ori
			) override {
				auto pMacro=this->ref.macro.find(macro);
				if(pMacro==this->ref.macro.end()) 
					throw std::runtime_error(
						std::string(macro)+" : no such macro found");
				auto& newInst=this->m.fixedInst.emplace_back();
				newInst=std::make_shared<Inst>();
				*newInst.get()={{x,y},ori,pMacro->second};
				this->ref.fixedInst[name]=newInst;
				return 1;
			};
			
		int createObstruction(
			String name,
			Coordinate l, Coordinate b, 
			Coordinate r, Coordinate t 
			) override {
				Rectangle<Coordinate> R={{l,b},{r,t}};
				this->m.obstructions.emplace_back()=
					std::make_shared<Obs>(name,R);
				return 1;
			}
						
		int macro_config(TIETYPE t,String macro) override {
			auto m=this->ref.macro.find(macro);
			if(m==this->ref.macro.end()) throw std::runtime_error(
				std::string("Wrong macro name in config ") + macro
				);
			this->config.tie[t]=m->second;
			return 1;
			}

		int checkerboard_distance(Coordinate spacing) override {
			this->config.checkerBoardSpacing=spacing;
			return 1;
			}
		
		int db_units(long db_units_micron) override {
			Micron::setDbUnit(db_units_micron);
			return 1;	
			}

		auto rows() 
		{
			Rows rows;
			std::for_each(
				this->m.row.begin(),this->m.row.end(),
				[&rows](auto& gRow) {
					rows.push_back({gRow->name,gRow->site->name,
						gRow->ori,
						gRow->orig.x,gRow->orig.y,
						gRow->step.x,gRow->step.y,
						gRow->num.x,gRow->num.y
						});
					});
			return rows;
		}
		
		void sanitize_rows(TieInserter<String,Coordinate> & P)
		{
			// Sanitize rows structure to remove overlapping rows
			for(auto& rowsPerSite: P.getYRowBuckets(*this))
			{
				// Get map<coordinate, row vector> for each site in this Y
				RowCutter<String,Coordinate>(this->m.row,rowsPerSite.second);
			}
		}
		
		void cut_rows(TieInserter<String,Coordinate>& P)
		{
			// Cut off fixed instances
			std::for_each(
				this->m.fixedInst.begin(),this->m.fixedInst.end(),
					[this](auto inst) {
				RowCutter<String,Coordinate>(this->m.row,inst->bbox());
				});
			// Cut off placement obstructions
			std::for_each(
				this->m.obstructions.begin(), this->m.obstructions.end(),
				[this](auto obst) {
				RowCutter<String,Coordinate>(this->m.row,*obst);
				});			
		}
		
		auto place()
		{
			std::map<std::string, std::vector<Placement> > rv;
			std::srand(2019);
			try {
				TieInserter<String,Coordinate> P;
				sanitize_rows(P);
				cut_rows(P);
				if(this->m.row.empty())
				{
					throw std::runtime_error(
						"No placement rows available");
				}

				for(auto i: {P.CheckerBoard(*this),P.BoundaryCells(*this)})
				{
					for(auto& pair: i)
					{
						auto& locs=rv[pair.first->name];
						for(auto&& p: pair.second)
						{
							locs.push_back({p.loc.x,p.loc.y,p.ori});
						}
					}
				}
			} catch ( const std::exception& e) {
				std::cerr << e.what() << std::endl;		
				}
			return rv;
		}
};

template<> AbstractBridge<const char*,pdnCoordType>::AbstractBridge()
{
}

template<> AbstractBridge<const char*,pdnCoordType>* 
AbstractBridge<const char*,pdnCoordType>::getPhysicalCellPlacer()
{
	return static_cast<
			AbstractBridge<const char*,pdnCoordType>*
				>(AbstractBridge::m_bridge.get());
}

#define SWIGTCL
#undef _TAPCELL_H_
#include <tapcell.h>
#undef AbstractBridge

using Placer = SpecialCellPlacer<const char*,pdnCoordType>;
using PlacerPtr = Placer*;

AbstractBridgeSwig::AbstractBridgeSwig()
{
	std::shared_ptr<Placer> ptr = std::make_shared<Placer>();
	ptr->init();
	m_adapter = ptr;	
}

int AbstractBridgeSwig::init()
{
	// Must never be called in theory
	return -1;
}

int AbstractBridgeSwig::createRow(
	String row, 
	String site,
	Coordinate origX, Coordinate origY,
	Orientation ori,
	int numX, int numY,
	int stepX, int stepY) {
		
		return 
			static_cast<PlacerPtr>(m_adapter.get())->createRow(
				row,site,origX,origY,ori,numX,numY,stepX,stepY
				);
	}

int AbstractBridgeSwig::createSite(
	String name,
	Coordinate x, Coordinate y,
	Symmetry symmetry 
) {
	return 
		static_cast<PlacerPtr>(m_adapter.get())->createSite(name,x,y,symmetry);
	}

int AbstractBridgeSwig::createMacro(
	String name,
	String site,
	Coordinate ox,Coordinate oy, 
	Coordinate x,Coordinate y,
	const std::vector<Symmetry>& symmetry) {
		return 
			static_cast<PlacerPtr>(m_adapter.get())->createMacro(
				name,site,ox,oy,x,y,symmetry);
	}

int AbstractBridgeSwig::createInst(
	String name,
	String macro,
	Coordinate x, Coordinate y,
	Orientation ori) {
		return static_cast<PlacerPtr>(m_adapter.get())->createInst(
			name,macro,x,y,ori);
	}

int AbstractBridgeSwig::createObstruction(
	String name,
	Coordinate l, Coordinate b, 
	Coordinate r, Coordinate t 
	) {
		return static_cast<PlacerPtr>(m_adapter.get())->createObstruction(
			name, l, b, r, t
			);
	}
AbstractBridgeSwig* AbstractBridgeSwig::getPhysicalCellPlacer()
{
	if(!AbstractBridgeSwig::m_bridge) 
	{
		AbstractBridgeSwig::m_bridge = std::make_shared<AbstractBridgeSwig>();
		
		AbstractBridgeSwig::m_bridge->init();
	}
		
	return AbstractBridgeSwig::m_bridge.get();
}

int AbstractBridgeSwig::macro_config(TIETYPE t,String macro) {
	return 
		static_cast<PlacerPtr>(m_adapter.get())->macro_config(t,macro);
	}

int AbstractBridgeSwig::checkerboard_distance(Coordinate w) {
	return 
		static_cast<PlacerPtr>(m_adapter.get())->checkerboard_distance(w);
	}

int AbstractBridgeSwig::db_units(long db_units_micron) {
	return 
		static_cast<PlacerPtr>(m_adapter.get())->db_units(db_units_micron);
	}

Rows AbstractBridgeSwig::rows()
{
	return
		static_cast<PlacerPtr>(m_adapter.get())->rows();
}

// Place physical instances
std::map<std::string, std::vector<Placement> > AbstractBridgeSwig::place()
{
	return 
		static_cast<PlacerPtr>(m_adapter.get())->place();
}
