#ifndef _TAPCELL_H_
#define _TAPCELL_H_

// Dealing with swig, pushed to use macro to bypass SWIG parsing shortcomings
#ifndef pdnCoordType
#define pdnCoordType double
#endif
#ifdef SWIGTCL
#define ADAPTER_FROM_SWIG_TO_TEMPLATE std::shared_ptr<void> m_adapter;
#define String const char*
// Pretty hacky trick here to bypass SWIG template parsing issues
// We're renaming the class on the fly for Swig
#define AbstractBridge AbstractBridgeSwig
#define NOIMPL ;
#define TEMP_ARGS
using Coordinate = pdnCoordType;
#else
#define TEMP_ARGS <const char*, pdnCoordType>
#define ADAPTER_FROM_SWIG_TO_TEMPLATE
#define NOIMPL { throw std::runtime_error(\
	"non-implemented virtual method called"); return -1; }
#endif

#include <memory>
#include <vector>
#include <map>

namespace Openroad
{
	namespace PowerDistributionNetwork
	{
		#ifndef _TAPCELL_H_TYPES_
		#define _TAPCELL_H_TYPES_
		enum class Symmetry { X, Y, R90 };
		enum class Orientation { 
			N=0,	NORTH=0, 				R0=0, 
			FS=1,	FLIPPED_SOUTH=1,	MX=1,
			FN=2,	FLIPPED_NORTH=2,	MY=2, 
			S=3,	SOUTH=3,				R180=3,
			W=4,	WEST=4,					R90=4,
			E=5,		EAST=5,					R270=5,
			FW=6,	FLIPPED_WEST=6,	MX90=6,
			FE=7,	FLIPPED_EAST=7,		MY90=7
			};
		enum class TIETYPE { 
			FILL,
			// CAP stands for "Row terminator" in TSMC terminology
			// Does not have to have an actual capacitor
			ENDCAP, 
			CAP_NWELL_INSIDE, 
			CAP_NWELL_OUTSIDE,
			TOP_OR_BOTTOM_NWELL_INSIDE,
			TOP_OR_BOTTOM_NWELL_OUTSIDE
		};
		
		struct Row
		{
			std::string name="undef_row", site="undef_site";
			Orientation ori{Orientation::N};
			pdnCoordType 
				orig_x=0, orig_y=0;
			long
				step_x=0, step_y=0,
				num_x=0, num_y=0;
		};
		
		using Rows = std::vector<Row>;
		
		// Special structure for placment resutls to facilitate SWIG export
		struct Placement
		{
			pdnCoordType x, y;
			Orientation ori;
		};
		
		using pdnResult = std::map<std::string, std::vector<Placement> >;
		#endif//_TAPCELL_H_TYPES_
		
		#ifndef SWIGTCL
		template <typename String=const char*, typename Coordinate=pdnCoordType>
		#endif
		class AbstractBridge : 
			public std::enable_shared_from_this<AbstractBridge TEMP_ARGS>
		{
			// Shall be created on access by an implementation class
			protected:
				static inline std::shared_ptr<AbstractBridge> m_bridge { NULL };
			
				ADAPTER_FROM_SWIG_TO_TEMPLATE;
			
		public:

			virtual int init() NOIMPL;
			
			AbstractBridge();
			
			virtual int createRow(
				String row, 
				String site,
				Coordinate origX, Coordinate origY,
				Orientation ori,
				int numX, int numY,
				int stepX, int stepY) NOIMPL;
				
			virtual int createSite(
				String name,
				Coordinate x, Coordinate y,
				Symmetry symmetry 
			) NOIMPL;

			virtual int createMacro(
				String name,
				String site,
				Coordinate ox,
				Coordinate oy, 
				Coordinate x,
				Coordinate y,
				const std::vector<Symmetry>& symmmetry) NOIMPL;
				
			virtual int createInst(
				String name,
				String macro,
				Coordinate x, Coordinate y,
				Orientation ori
				) NOIMPL;
				
			virtual int createObstruction(
				String name,
				Coordinate l, Coordinate b, 
				Coordinate r, Coordinate t 
				) NOIMPL;
			
			virtual ~AbstractBridge() = default;
			
			static AbstractBridge* getPhysicalCellPlacer();
			
			// Set 
			virtual int macro_config(TIETYPE,String) NOIMPL;
			virtual int checkerboard_distance(Coordinate) NOIMPL;
			virtual int db_units(long units_per_micro) NOIMPL;

			// Place physical instances
			pdnResult place();
			
			Rows rows();
		};
	}
}
#undef NOIMPL
#undef ADAPTER_FROM_SWIG_TO_TEMPLATE
#undef TEMP_ARGS
#endif//_TAPCELL_H_
