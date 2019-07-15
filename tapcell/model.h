#ifndef _MODEL_H
#define _MODEL_H

// Definition of placement data model
#include "tapcell.h"
#include <memory>
#include <algorithm>
#include <unordered_map>
#include <map>
#include <iostream>
#include <iomanip>
#include <cmath>

namespace Openroad {
	
	namespace PowerDistributionNetwork {
		
		template <typename Coordinate=double> class Micron {
		
			struct {
				Coordinate value{0};
				} m;
			
			inline static Coordinate m_db_unit{0};
			
			public:
			
				static void setDbUnit(Coordinate um) { 
					Micron::m_db_unit=um;
					}
			
				Micron() = default;
				
				Micron(double um) { m.value = um; }
				
				Coordinate db_unit() const 
				{
					return Micron::m_db_unit * m.value;
				}
			};

		template <typename Coordinate> struct Point {
			Coordinate x, y;
			inline bool cmpyx(const Point& ano) const {
				if( y < ano.y ) return 1;
				if(y==ano.y) return x < ano.x;
				return 0;
				}
			inline Point operator*(const Point& ano) const {
				return {x*ano.x,y*ano.y};
				}
			inline Point operator+(const Point& ano) const {
				return {x+ano.x,y+ano.y};
				}
			friend std::ostream& operator<<( std::ostream& o, const Point& p ) {
				return o << std::setprecision (15) 
					<< "(" << p.x << "," << p.y << ")";
				}
			};
		
		template <typename Coordinate>  struct MicronPoint : 
				public Point<Micron<Coordinate>> {
			operator Point<Coordinate>() {
				return {this->x.db_unit(),this->y.db_unit()};
				}
			};
			
		template <typename Coordinate> struct Rectangle {
			Point<Coordinate> lb, rt;
			
			inline auto left() const { return lb.x; }
			inline auto right() const { return rt.x; }
			inline auto bottom() const { return lb.y; }
			inline auto top() const { return rt.y; }
			
			Rectangle() {}
			Rectangle(const Point<Coordinate>& lb,const Point<Coordinate>& rt):
				lb(lb),rt(rt) {}
			Rectangle(Point<Coordinate>& p,Coordinate w,Coordinate h) {
				lb=p, rt=p+Point<Coordinate>({w,h});
				}
			friend std::ostream& operator<<( std::ostream& o, 
				const Rectangle& r ) {
				return o << std::setprecision (15)
					<< "{" << r.lb << ":" << r.rt << "}";
				}
			auto operator+(const Point<Coordinate>& shift) const {
					Rectangle<Coordinate> rv;
					lb+=shift, rt+=shift;
				}
			bool intersects(const Rectangle& ano) const {
				return ! (
					(right() < ano.left() || left() > ano.right())
									||
					(top() < ano.bottom() || bottom()>ano.top())
					);
				}
			};
			
		template<typename Object> using PtrMap = 
			std::unordered_map<std::string,std::shared_ptr<Object>>;
			
		template<typename Object> using PtrVector=
			std::vector<std::shared_ptr<Object>>;
			
		template<class Object, typename T> 
		void SetIndex(PtrVector<Object>& v, T Object::*MemPtr) {
			T idx{0};
			for(auto& i:v) i.get()->*MemPtr=idx++;
			};
			
		template<class Object, typename T> 
		auto DecreaseIndexOrder(PtrVector<Object>& v, T Object::*MemPtr) {
			std::vector<T> idxVec(v.size());
			auto walker=idxVec.begin();
			for(auto& i:v) *walker++=i.get()->*MemPtr;
			std::sort(idxVec.begin(),idxVec.end(),std::greater<>());
			return idxVec;
			};		
		
		template<typename Coordinate, typename Object> using CoordVectorMap=
			std::map<Coordinate, PtrVector<Object>>;

		template <typename String, typename Coordinate> 
			struct PlacementDataContainer
		{
			using Micron = class Micron<Coordinate>;
			
			struct Site {
				std::string name;
				MicronPoint<Coordinate> size;
				Symmetry sym;
				};
		
			struct Macro {
				std::string name;
				MicronPoint<Coordinate> origin, size;
				std::set<Symmetry> sym;
				std::shared_ptr<Site> site;
				};

			struct Instance {
				Point<Coordinate> loc; 
				Orientation ori; 
				std::shared_ptr<Macro>macro;
				std::string name;
				Point<Coordinate> size(Orientation o) const {
					switch(o){
						case Orientation::N:
						case Orientation::S:
						case Orientation::FN:
						case Orientation::FS: return macro->size;
						default:;
						};
					decltype(macro->size) rv{macro->size.y,macro->size.x};
					return rv;
					}
					
				inline auto bbox() const {
					return Rectangle<Coordinate>(loc,loc+size(ori));
					}
				};
				
				
			struct PlacementObstruction : public Rectangle<Coordinate> {
				std::string name;
				PlacementObstruction(
					String name,
					const Rectangle<Coordinate>& rect):
						name{name},
						Rectangle<Coordinate> (rect) {
						}
				};
		
			struct Row {
				std::string name;
				Orientation ori;
				using Location = Point<Coordinate>;
				Location orig;
				Point<int> num, step;
				std::shared_ptr<Site> site;
				size_t index{0};
				
				inline Location size() const 
				{ 
					if(nullptr==site) 
					{
						throw std::runtime_error(
							this->name + ": row lacking site");
					}
					return site->size; 
				}
				
				inline Rectangle<Coordinate> bbox() const {
					auto p=num*step;
					Point<Coordinate> p1{
						static_cast<Coordinate>(p.x),
						static_cast<Coordinate>(p.y)
						};
					return {orig,orig+p1+size()};	
					}
				
				inline bool operator<(const Row& ano) const {
					return orig.cmpyx(ano.orig);
					}

				inline auto onGrid(Coordinate x) const {
					int steps=ceil((x-orig.x)/step.x);
					return orig.x+steps*step.x;
					}
				
				inline auto spread(Coordinate beg, Coordinate shift) const {
					std::vector<Location> rv;
					beg=onGrid(beg+orig.x);
					auto end=orig.x+num.x*step.x;
					if(beg+shift>end)
					{	// Ignore beginning all together and place in mid-row
						rv.push_back({onGrid((end+orig.x)/2),orig.y});
					} else {
						for(auto x=beg;x<end;x+=shift)
							rv.push_back({onGrid(x),orig.y});
						}
					return rv;
					}
				
				friend std::ostream& operator<<( std::ostream& o, 
					const Row& row ) {
					return o << std::setprecision (15) 
							<< row.name << " orig=" << row.orig 
							<< " num=" << row.num 
							<< " step=" << row.step ;
					}
				};
		
			struct {
				PtrVector<Site> site;
				PtrVector<Macro> macro;
				PtrVector<Row> row;
				PtrVector<Instance> fixedInst;
				PtrVector<PlacementObstruction> obstructions;
			} m;
	
			struct {
				PtrMap<Site> site;
				PtrMap<Macro> macro;
				PtrMap<Row> row;
				PtrMap<Instance> fixedInst;
			} ref;
	
			struct {
				std::map<TIETYPE,std::shared_ptr<Macro>> tie;
				Coordinate checkerBoardSpacing{0};
			} config;
				
		};
	#include "tieInserter.h"
	#include "rowCutter.h"
	}
}

#endif//_MODEL_H
